// Generaed by BinWips {#BinWipsVersion#}
using System;
using BinWips;
using System.Diagnostics;
using System.IO.Pipes;
using System.Threading.Tasks;
using System.IO;


// attributes which can be used to identify this assembly as a BinWips
// https://stackoverflow.com/questions/1936953/custom-assembly-attributes
[assembly: BinWips("{#BinWipsVersion#}")]
{#AssemblyAttributes#}
namespace {#Namespace#} {
         
    {#ClassAttributes#}
    class {#ClassName#} 
    {
        
        public static void Main(string[] args)
        {
            // script is inserted in base64 so we need to decode it
            var runtimeSetup = DecodeBase64("{#RuntimeSetup#}");
            var funcName = "{#FunctionName#}";
            var ending = "";
            if (AreArgsHelp(args))
            {
                ending = $"Get-Help -Detailed {funcName}; Write-host 'Created with BinWips v{#BinWipsVersion#}'";
            }
            else
            {
                // Console.WriteLine("Args:");
                // Console.WriteLine(string.Join("\n", args));
                // Console.WriteLine("End Args");
                ending = $"{funcName} {string.Join(" ", args)}";
                //Console.WriteLine($"Call Command: {ending}");
                StartServer();
            }

            var script = DecodeBase64("{#Script#}");
            var wrappedScript = $"{runtimeSetup}\n\n function {funcName}\n {{\n {script}\n }}\n{ending}";
            var encodedCommand = EncodeBase64(wrappedScript);

            // call PWSH to execute the script passing in the args
            var psi = new ProcessStartInfo(@"{#PowerShellPath#}");
            // e.g -NoProfile -NoLogo -EncodedCommand
            psi.Arguments = "{#PowerShellArguments#}" + " " + encodedCommand;

            var process = Process.Start(psi);
            process.WaitForExit();
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

        static void StartServer()
        {
            Task.Factory.StartNew(() =>
            {
                var server = new NamedPipeServerStream("BinWipsPipe{#BinWipsPipeGuid#}");
                server.WaitForConnection();
                StreamReader reader = new StreamReader(server);
                StreamWriter writer = new StreamWriter(server);
                while (true)
                {
                    var line = reader.ReadLine();
                    try
                    {
                        var assembly = System.Reflection.Assembly.GetExecutingAssembly();
                        var resourcename = line;
                        // get the resouce from the assembly
                        using (var stream = assembly.GetManifestResourceStream(resourcename))
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