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

import edu.wpi.first.util.sendable.SendableRegistry;
import edu.wpi.first.wpilibj.Joystick;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.drive.DifferentialDrive;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;



/**
 * This is a demo program showing the use of the DifferentialDrive class, specifically it contains
 * the code necessary to operate a robot with tank drive.
 */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    private final DifferentialDrive robotDrive;
    private final Joystick leftStick;
    private final Joystick rightStick;
    
    private final PWMSparkMax leftMotor = new PWMSparkMax(0);
    private final PWMSparkMax rightMotor = new PWMSparkMax(1);
    
    
    /** Called once at the beginning of the robot program. */
    public Robot()
    {
        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightMotor.setInverted(true);
        
        robotDrive = new DifferentialDrive(leftMotor::set, rightMotor::set);
        leftStick = new Joystick(0);
        rightStick = new Joystick(1);
        
        SendableRegistry.addChild(robotDrive, leftMotor);
        SendableRegistry.addChild(robotDrive, rightMotor);
    }
    
    
    @Override
    public void teleopPeriodic()
    {
        robotDrive.tankDrive(-leftStick.getY(), -rightStick.getY());
    }
}
