// Generaed by BinWips {#BinWipsVersion#}
using System;
using BinWips;
using System.Management.Automation;
using System.Linq;

// attributes which can be used to identify this assembly as a BinWips
// https://stackoverflow.com/questions/1936953/custom-assembly-attributes
[assembly: BinWips("{#BinWipsVersion#}")]
{#AssemblyAttributes#}
         
         // main namespace

         namespace {#Namespace#} {
         
               {#ClassAttributes#}
               class {#ClassName#} {
                  public static void Main(string[] args)
        {
            var powerShell = PowerShell.Create();

            // script is inserted in base64 so we need to decode it
            var runtimeSetup = DecodeBase64("{#RuntimeSetup#}");
            var script = DecodeBase64("{#Script#}");

            // build runspace and execute it
            // additional setup could be added 
            // by default we do an out string so that
            // console output looks nice 
            powerShell
                      .AddScript(runtimeSetup)
                      .AddScript(script)
                      .AddParameters(args)
                      .AddCommand("Out-String");
            var results = powerShell.Invoke();

            // output the results
            foreach (var result in results)
            {
                Console.WriteLine(result);
            }
        }
        static string DecodeBase64(string encoded)
        {
            var decodedBytes = Convert.FromBase64String(encoded);
            var text = System.Text.Encoding.Unicode.GetString(decodedBytes);
            return text;
        }
    }
}