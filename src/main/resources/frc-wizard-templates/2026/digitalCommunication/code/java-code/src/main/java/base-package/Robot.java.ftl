<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
${data.copyright}

package ${data.basePackage};

import java.util.Optional;

import edu.wpi.first.wpilibj.DigitalOutput;
import edu.wpi.first.wpilibj.DriverStation;
import edu.wpi.first.wpilibj.TimedRobot;



/**
 * This is a sample program demonstrating how to communicate to a light controller from the robot
 * code using the roboRIO's DIO ports.
 */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    // define ports for digitalcommunication with light controller
    static final int ALLIANCE_PORT = 0;
    static final int ENABLED_PORT = 1;
    static final int AUTONOMOUS_PORT = 2;
    static final int ALERT_PORT = 3;
    
    private final DigitalOutput allianceOutput = new DigitalOutput(ALLIANCE_PORT);
    private final DigitalOutput enabledOutput = new DigitalOutput(ENABLED_PORT);
    private final DigitalOutput autonomousOutput = new DigitalOutput(AUTONOMOUS_PORT);
    private final DigitalOutput alertOutput = new DigitalOutput(ALERT_PORT);
    
    
    @Override
    public void robotPeriodic()
    {
        boolean setAlliance = false;
        Optional<DriverStation.Alliance> alliance = DriverStation.getAlliance();
        if (alliance.isPresent())
        {
            setAlliance = alliance.get() == DriverStation.Alliance.Red;
        }
        
        // pull alliance port high if on red alliance, pull low if on blue alliance
        allianceOutput.set(setAlliance);
        
        // pull enabled port high if enabled, low if disabled
        enabledOutput.set(DriverStation.isEnabled());
        
        // pull auto port high if in autonomous, low if in teleop (or disabled)
        autonomousOutput.set(DriverStation.isAutonomous());
        
        // pull alert port high if match time remaining is between 30 and 25 seconds
        var matchTime = DriverStation.getMatchTime();
        alertOutput.set(matchTime <= 30 && matchTime >= 25);
    }
    
    
    /** Close all resources. */
    @Override
    public void close()
    {
        allianceOutput.close();
        enabledOutput.close();
        autonomousOutput.close();
        alertOutput.close();
        super.close();
    }
}
