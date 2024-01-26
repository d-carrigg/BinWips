// Generaed by BinWips {#BinWipsVersion#}
using System;
using BinWips;
using System.Diagnostics;
using System.IO.Pipes;
using System.Threading.Tasks;
using System.IO;
using System.Linq;
using System.Reflection;

// attributes which can be used to identify this assembly as a BinWips
// https://stackoverflow.com/questions/1936953/custom-assembly-attributes
[assembly:BinWips("{#BinWipsVersion#}")]
{#AssemblyAttributes#}
namespace {#Namespace#} {
         
    {#ClassAttributes#}
    class {#ClassName#} 
    {

        static {#ClassName#}()
        {
            // load the assembly into memory
            ProgramAssembly = System.Reflection.Assembly.GetExecutingAssembly();
        }
        
        public static void Main(string[] args)
        {
            // script is inserted in base64 so we need to decode it
            var runtimeSetup = DecodeBase64("{#RuntimeSetup#}");
            var funcName = "{#FunctionName#}";
            var ending = "";
            SetVerboseMode(args);
            if (AreArgsHelp(args))
            {
                ending = $"Get-Help -Detailed {funcName}; Write-host 'Created with BinWips v{#BinWipsVersion#}'";
                Log("Call Command: {0}", ending);
            }
            else
            {
                ending = $"{funcName} {string.Join(" ", args)}";
                Log("Call Command: {0}", ending);
                StartServer();
            }

            var script = DecodeBase64("{#Script#}");
            var wrappedScript = $"{runtimeSetup}\n\n function {funcName}\n {{\n {script}\n }}\n{ending}";
            var encodedCommand = EncodeBase64(wrappedScript);

            // resolve the path to the powershell exe
            var resolved = ResolvePowerShellPath(@"{#PowerShellPath#}");

            if(resolved == null) throw new Exception("Could not find powershell in path");

            // call PWSH to execute the script passing in the args
            var psi = new ProcessStartInfo(resolved);
            Log("PowerShell Path: {0}", psi.FileName);
            // e.g -NoProfile -NoLogo -EncodedCommand
            psi.Arguments = "{#PowerShellArguments#}" + " " + encodedCommand;
            var process = Process.Start(psi);
            process.WaitForExit();
        }


        static string ResolvePowerShellPath(string filename)
        {
            var userPath = Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.Process) + ";"
                     + Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.User) + ";"
                     + Environment.GetEnvironmentVariable("PATH", EnvironmentVariableTarget.Machine);

            var directories = userPath.Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

            foreach (var dir in directories)
            {
                var fullpath = Path.Combine(dir, filename);
                if (File.Exists(fullpath)) return fullpath;
            }

            if(System.Runtime.InteropServices.RuntimeInformation.IsOSPlatform(System.Runtime.InteropServices.OSPlatform.Windows)){
                return SearchForPowerShellInDirs(filename, new [] {
                    // pwsh on windows
                    @"c:\Program Files\PowerShell", 
                    // windows powershell on windows
                    @"c:\Windows\System32\WindowsPowerShell\v1.0",
                });
            } else {
                return SearchForPowerShellInDirs(filename, new [] {
                    // pwsh on linux
                    @"/usr/bin",
                });
            }

      
            return null;
        }

        static string SearchForPowerShellInDirs(string filename, string[] known_dirs){
            foreach(var dir in known_dirs){
                var entries = Directory.EnumerateFiles(dir, filename, new EnumerationOptions{
                    MatchCasing = MatchCasing.CaseInsensitive,
                    RecurseSubdirectories = true,
                    MaxRecursionDepth = 2
                });

                if(entries.Any()){
                    return entries.First();
                }
            }
            return null;
        }
        private static bool VerboseMode = false;
        static void SetVerboseMode(string[] args){
            if (args.Length == 0) return;
            if(args.Any(a => a.ToLower() == "-verbose")){
                VerboseMode = true;
            }
        }

        private static void Log(string messageFormat, params object[] args)
        {
            if (VerboseMode)
            {
                Console.WriteLine(messageFormat, args);
            }
        }

        static bool AreArgsHelp(string[] args)
        {
            if (args.Length != 1) return false;
            string lower = args[0].ToLower();
            return lower == "help" || lower == "-h" || lower == "--help";
        }
        static string DecodeBase64(string encoded)
            => System.Text.Encoding.Unicode.GetString(Convert.FromBase64String(encoded));

        static string EncodeBase64(string text)
         => Convert.ToBase64String(System.Text.Encoding.Unicode.GetBytes(text));

        static Assembly ProgramAssembly;

        static void StartServer()
        {
            Task.Factory.StartNew(() =>
            {
                var server = new NamedPipeServerStream("BinWipsPipe{#BinWipsPipeGuid#}");
                Log("Waiting for connection on pipe: {0}", "BinWipsPipe{#BinWipsPipeGuid#}");
                server.WaitForConnection();
                StreamReader reader = new StreamReader(server);
                StreamWriter writer = new StreamWriter(server);
                while (true)
                {
                    var resourceName = reader.ReadLine();
                    try
                    {
                        Log("Requesting Resource: {0}", resourceName);
                        // get the resouce from the assembly
                        using (var stream = ProgramAssembly.GetManifestResourceStream(resourceName))
                        {
                            using (var resourceReader = new System.IO.StreamReader(stream))
                            {
                                var text = resourceReader.ReadToEnd();
                                writer.WriteLine(text);
                                writer.Flush();
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        Log("Error getting resource: {0}", ex.Message);
                        // invalid resource
                        writer.WriteLine("Invalid Resource");
                        writer.WriteLine(ex.Message);
                        writer.Flush();
                    }
                }
            });
        }
    }
}