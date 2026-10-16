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
import edu.wpi.first.wpilibj.drive.MecanumDrive;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;



/** This is a demo program showing how to use Mecanum control with the MecanumDrive class. */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    private static final int FRONT_LEFT_CHANNEL = 2;
    private static final int REAR_LEFT_CHANNEL = 3;
    private static final int FRONT_RIGHT_CHANNEL = 1;
    private static final int REAR_RIGHT_CHANNEL = 0;
    
    private static final int JOYSTICK_CHANNEL = 0;
    
    private final MecanumDrive robotDrive;
    private final Joystick stick;
    
    
    /** Called once at the beginning of the robot program. */
    public Robot()
    {
        PWMSparkMax frontLeft = new PWMSparkMax(FRONT_LEFT_CHANNEL);
        PWMSparkMax rearLeft = new PWMSparkMax(REAR_LEFT_CHANNEL);
        PWMSparkMax frontRight = new PWMSparkMax(FRONT_RIGHT_CHANNEL);
        PWMSparkMax rearRight = new PWMSparkMax(REAR_RIGHT_CHANNEL);
        
        // Invert the right side motors.
        // You may need to change or remove this to match your robot.
        frontRight.setInverted(true);
        rearRight.setInverted(true);
        
        robotDrive = new MecanumDrive(frontLeft::set, rearLeft::set, frontRight::set, rearRight::set);
        
        stick = new Joystick(JOYSTICK_CHANNEL);
        
        SendableRegistry.addChild(robotDrive, frontLeft);
        SendableRegistry.addChild(robotDrive, rearLeft);
        SendableRegistry.addChild(robotDrive, frontRight);
        SendableRegistry.addChild(robotDrive, rearRight);
    }
    
    
    @Override
    public void teleopPeriodic()
    {
        // Use the joystick Y axis for forward movement, X axis for lateral
        // movement, and Z axis for rotation.
        robotDrive.driveCartesian(-stick.getY(), -stick.getX(), -stick.getZ());
    }
}
