// Generaed by BinWips {#BinWipsVersion#}
using System;
using BinWips;
using System.Diagnostics;

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
            if (args.Length == 1 && args[0] == "help")
            {
                ending = $"Get-Help -Detailed {funcName}";
            }
            else
            {
                ending = $"{funcName} {string.Join(" ", args)}";
            }

            var script = DecodeBase64("{#Script#}");
            var wrappedScript = $"{runtimeSetup}\n\n function {funcName}\n {{\n {script}\n }}\n{ending}";


            var encodedCommand = EncodeBase64(wrappedScript);

            // call PWSH to execute the script passing in the args
            var psi = new ProcessStartInfo(@"pwsh.exe");
            psi.Arguments = "-NoProfile -NoLogo -WindowStyle Hidden -EncodedCommand " + encodedCommand;
            //psi.RedirectStandardInput = true;
            var process = Process.Start(psi);
            process.EnableRaisingEvents = true;

            process.WaitForExit();

        }
        static string DecodeBase64(string encoded)
        {
            var decodedBytes = Convert.FromBase64String(encoded);
            var text = System.Text.Encoding.Unicode.GetString(decodedBytes);
            return text;
        }

        static string EncodeBase64(string text)
        {
            var bytes = System.Text.Encoding.Unicode.GetBytes(text);
            var encoded = Convert.ToBase64String(bytes);
            return encoded;
        }
    }
}