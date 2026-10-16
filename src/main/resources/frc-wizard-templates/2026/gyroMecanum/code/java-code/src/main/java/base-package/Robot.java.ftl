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
import edu.wpi.first.wpilibj.AnalogGyro;
import edu.wpi.first.wpilibj.Joystick;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.drive.MecanumDrive;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;



/**
 * This is a sample program that uses mecanum drive with a gyro sensor to maintain rotation vectors
 * in relation to the starting orientation of the robot (field-oriented controls).
 */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    // gyro calibration constant, may need to be adjusted;
    // gyro value of 360 is set to correspond to one full revolution
    private static final double VOLTS_PER_DEGREE_PER_SECOND = 0.0128;
    
    private static final int FRONT_LEFT_CHANNEL = 0;
    private static final int REAR_LEFT_CHANNEL = 1;
    private static final int FRONT_RIGHT_CHANNEL = 2;
    private static final int REAR_RIGHT_CHANNEL = 3;
    private static final int GYRO_PORT = 0;
    private static final int JOYSTICK_PORT = 0;
    
    private final MecanumDrive robotDrive;
    private final AnalogGyro gyro = new AnalogGyro(GYRO_PORT);
    private final Joystick joystick = new Joystick(JOYSTICK_PORT);
    
    
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
        
        gyro.setSensitivity(VOLTS_PER_DEGREE_PER_SECOND);
        
        SendableRegistry.addChild(robotDrive, frontLeft);
        SendableRegistry.addChild(robotDrive, rearLeft);
        SendableRegistry.addChild(robotDrive, frontRight);
        SendableRegistry.addChild(robotDrive, rearRight);
    }
    
    
    /** Mecanum drive is used with the gyro angle as an input. */
    @Override
    public void teleopPeriodic()
    {
        robotDrive.driveCartesian(
                -joystick.getY(), -joystick.getX(), -joystick.getZ(), gyro.getRotation2d());
    }
}
