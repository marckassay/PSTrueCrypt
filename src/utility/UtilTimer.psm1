using namespace System.Timers

class UtilTimer
{
    static [UtilTimer] $instance
    
    static [UtilTimer] Get()
    {
        if ([UtilTimer]::instance -eq $null) {
            [UtilTimer]::instance = [UtilTimer]::new()
        }

        return [UtilTimer]::instance
    }


    [System.Timers.Timer] $Timer

    [void] Start()
    {
        $this.Timer.Start()
    }

    [void] Stop()
    {
        $this.Timer.Stop()
    }

    [System.Timers.Timer] New()
    {
        if(!$this.Timer) {
            $this.Timer = New-Object -TypeName 'System.Timers.Timer'
            $this.Timer.Interval = 2000
            #$this.Timer.AutoReset = $True
        }

        return $this.Timer
    }
}


function Start-Timer
{
    [UtilTimer]::Get().Start()
}
function Stop-Timer
{
    [UtilTimer]::Get().Stop()
}
function New-Timer
{
   return [UtilTimer]::Get().New()
}


Export-ModuleMember -Function Start-Timer
Export-ModuleMember -Function Stop-Timer
Export-ModuleMember -Function New-Timer 