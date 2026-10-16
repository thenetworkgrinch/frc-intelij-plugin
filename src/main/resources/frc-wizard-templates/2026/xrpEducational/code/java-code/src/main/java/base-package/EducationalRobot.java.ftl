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

import edu.wpi.first.hal.DriverStationJNI;
import edu.wpi.first.util.WPIUtilJNI;
import edu.wpi.first.wpilibj.DriverStation;
import edu.wpi.first.wpilibj.RobotBase;
import edu.wpi.first.wpilibj.internal.DriverStationModeThread;



/** Educational robot base class. Do NOT use for competitions. This is a simple robot used for teaching purposes. */
public class EducationalRobot extends RobotBase
{
    public EducationalRobot() {}
    
    
    public void disabled() {}
    
    
    public void run() {}
    
    
    public void autonomous()
    {
        run();
    }
    
    
    public void teleop()
    {
        run();
    }
    
    
    public void test()
    {
        run();
    }
    
    
    private volatile boolean exit;
    
    
    @Override
    public void startCompetition()
    {
        DriverStationModeThread modeThread = new DriverStationModeThread();
        
        int event = WPIUtilJNI.createEvent(false, false);
        
        DriverStation.provideRefreshedDataEventHandle(event);
        
        // Tell the DS that the robot is ready to be enabled
        DriverStationJNI.observeUserProgramStarting();
        
        while (!Thread.currentThread().isInterrupted() && !exit)
        {
            if (isDisabled())
            {
                modeThread.inDisabled(true);
                disabled();
                modeThread.inDisabled(false);
                while (isDisabled())
                {
                    try
                    {
                        WPIUtilJNI.waitForObject(event);
                    }
                    catch (InterruptedException e)
                    {
                        Thread.currentThread().interrupt();
                    }
                }
            }
            else if (isAutonomous())
            {
                modeThread.inAutonomous(true);
                autonomous();
                modeThread.inAutonomous(false);
                while (isAutonomousEnabled())
                {
                    try
                    {
                        WPIUtilJNI.waitForObject(event);
                    }
                    catch (InterruptedException e)
                    {
                        Thread.currentThread().interrupt();
                    }
                }
            }
            else if (isTest())
            {
                modeThread.inTest(true);
                test();
                modeThread.inTest(false);
                while (isTest() && isEnabled())
                {
                    try
                    {
                        WPIUtilJNI.waitForObject(event);
                    }
                    catch (InterruptedException e)
                    {
                        Thread.currentThread().interrupt();
                    }
                }
            }
            else
            {
                modeThread.inTeleop(true);
                teleop();
                modeThread.inTeleop(false);
                while (isTeleopEnabled())
                {
                    try
                    {
                        WPIUtilJNI.waitForObject(event);
                    }
                    catch (InterruptedException e)
                    {
                        Thread.currentThread().interrupt();
                    }
                }
            }
        }
        
        DriverStation.removeRefreshedDataEventHandle(event);
        modeThread.close();
    }
    
    
    @Override
    public void endCompetition()
    {
        exit = true;
    }
}
