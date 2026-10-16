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

import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.Ultrasonic;
import edu.wpi.first.wpilibj.shuffleboard.Shuffleboard;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;



/**
 * This is a sample program demonstrating how to read from a ping-response ultrasonic sensor with
 * the {@link Ultrasonic class}.
 */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    // Creates a ping-response Ultrasonic object on DIO 1 and 2.
    Ultrasonic rangeFinder = new Ultrasonic(1, 2);
    
    
    /** Called once at the beginning of the robot program. */
    public Robot()
    {
        // Add the ultrasonic on the "Sensors" tab of the dashboard
        // Data will update automatically
        Shuffleboard.getTab("Sensors").add(rangeFinder);
    }
    
    
    @Override
    public void teleopPeriodic()
    {
        // We can read the distance in millimeters
        double distanceMillimeters = rangeFinder.getRangeMM();
        // ... or in inches
        double distanceInches = rangeFinder.getRangeInches();
        
        // We can also publish the data itself periodically
        SmartDashboard.putNumber("Distance[mm]", distanceMillimeters);
        SmartDashboard.putNumber("Distance[inch]", distanceInches);
    }
    
    
    @Override
    public void testInit()
    {
        // By default, the Ultrasonic class polls all ultrasonic sensors in a round-robin to prevent
        // them from interfering from one another.
        // However, manual polling is also possible -- note that this disables automatic mode!
        rangeFinder.ping();
    }
    
    
    @Override
    public void testPeriodic()
    {
        if (rangeFinder.isRangeValid())
        {
            // Data is valid, publish it
            SmartDashboard.putNumber("Distance[mm]", rangeFinder.getRangeMM());
            SmartDashboard.putNumber("Distance[inch]", rangeFinder.getRangeInches());
            
            // Ping for next measurement
            rangeFinder.ping();
        }
    }
    
    
    @Override
    public void testExit()
    {
        // Enable automatic mode
        Ultrasonic.setAutomaticMode(true);
    }
}
