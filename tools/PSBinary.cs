// Generaed by BinWips 0.1
using System;
using BinWips;
using System.Management.Automation; 

// attributes which can be used to identify this assembly as a BinWips
// https://stackoverflow.com/questions/1936953/custom-assembly-attributes
[assembly: BinWips("0.1")]

// main namespace
namespace MyNamespace {

    class Program {
        public static void Main(string[] args) {
            var powerShell = PowerShell.Create();
            
            // script is inserted in base64 so we need to decode it
            var decodedBytes = Convert.FromBase64String("RwBlAHQALQBQAHIAbwBjAGUAcwBzAA==");
            var script = System.Text.Encoding.Unicode.GetString(decodedBytes);
           
            // build runspace and execute it
            // additional setup could be added 
            // by default we do an out string so that
            // console output looks nice 
            powerShell.AddScript(script)
                        .AddCommand("Out-String");
            var results = powerShell.Invoke();

            // output the results
            foreach(var result in results){
                Console.WriteLine(result);
            }
        }
    }
}
