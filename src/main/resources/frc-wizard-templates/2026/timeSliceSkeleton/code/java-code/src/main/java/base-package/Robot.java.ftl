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

<#if data.getIncludeKotlinSupport()>
import edu.wpi.first.hal.FRCNetComm.tInstances;
import edu.wpi.first.hal.FRCNetComm.tResourceType;
import edu.wpi.first.hal.HAL;
</#if>
import edu.wpi.first.wpilibj.TimesliceRobot;
import edu.wpi.first.wpilibj.livewindow.LiveWindow;
<#if data.getIncludeKotlinSupport()>
import edu.wpi.first.wpilibj.util.WPILibVersion;
</#if>


/**
 * The methods in this class are called automatically corresponding to each mode, as described in
 * the TimesliceRobot documentation. If you change the name of this class or the package after
 * creating this project, you must also update the Main.java file in the project.
 */
public class ${data.robotClassSimpleName} extends TimesliceRobot
{
    /** Robot constructor. */
    public Robot()
    {
        <#if data.getIncludeKotlinSupport()>
        // Report the use of Kotlin for "FRC Usage Report" statistics.
        // Please only remove if you remove *all* use of Kotlin from the robot.
        HAL.report(tResourceType.kResourceType_Language, tInstances.kLanguage_Kotlin, 0, WPILibVersion.Version);
        
        </#if>
        // Run robot periodic() methods for 5 ms, and run controllers every 10 ms
        super(0.005, 0.01);
        
        // LiveWindow causes drastic overruns in robot periodic methods that will
        // interfere with controllers
        LiveWindow.disableAllTelemetry();
        
        // Runs for 2 ms after robot periodic methods
        schedule(() -> {}, 0.002);
        
        // Runs for 2 ms after first controller method
        schedule(() -> {}, 0.002);
        
        // Total usage:
        // 5 ms (robot) + 2 ms (controller 1) + 2 ms (controller 2) = 9 ms
        // 9 ms / 10 ms -> 90% allocated
    }
    
    
    @Override
    public void robotPeriodic() {}
    
    
    @Override
    public void autonomousInit() {}
    
    
    @Override
    public void autonomousPeriodic() {}
    
    
    @Override
    public void teleopInit() {}
    
    
    @Override
    public void teleopPeriodic() {}
    
    
    @Override
    public void disabledInit() {}
    
    
    @Override
    public void disabledPeriodic() {}
    
    
    @Override
    public void testInit() {}
    
    
    @Override
    public void testPeriodic() {}
}
