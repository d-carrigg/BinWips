// See https://aka.ms/new-console-template for more information
// Start a PowerShell runspace
using System.Management.Automation.Runspaces;

public class Program
{
    public static void Main(string[] args)
    {

        var powerShell = System.Management.Automation.PowerShell.Create();

        var setupScript = """

    function Foo {
        [CmdletBinding()]
        param($Foo, [string]$Bar)

        echo $Foo
        echo $Bar
    }

""";
        var script = """
    [CmdletBinding()]
    param($Param1, [string]$Param2, $Param3)

    echo $Param1

    Get-Process | Select-Object -First 5 | Format-Table -AutoSize

    Foo -Foo "Hello" -Bar "World"
""";
        powerShell
        .AddScript(setupScript)
        .AddScript(script)
        .AddParameters(args);
        var result = powerShell
                        .AddCommand("Out-String")
                        .Invoke();

        foreach (var psObject in result)
        {
            Console.WriteLine(psObject);
        }



    }
}

