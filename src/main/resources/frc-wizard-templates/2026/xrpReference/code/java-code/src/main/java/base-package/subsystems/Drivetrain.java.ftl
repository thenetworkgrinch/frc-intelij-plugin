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

package ${data.basePackage}.subsystems;

import edu.wpi.first.util.sendable.SendableRegistry;
import edu.wpi.first.wpilibj.BuiltInAccelerometer;
import edu.wpi.first.wpilibj.Encoder;
import edu.wpi.first.wpilibj.drive.DifferentialDrive;
import edu.wpi.first.wpilibj.xrp.XRPGyro;
import edu.wpi.first.wpilibj.xrp.XRPMotor;
import edu.wpi.first.wpilibj2.command.SubsystemBase;



public class Drivetrain extends SubsystemBase
{
    private static final double GEAR_RATIO =
            (30.0 / 14.0) * (28.0 / 16.0) * (36.0 / 9.0) * (26.0 / 8.0); // 48.75:1
    private static final double COUNTS_PER_MOTOR_SHAFT_REV = 12.0;
    private static final double COUNTS_PER_REVOLUTION = COUNTS_PER_MOTOR_SHAFT_REV * GEAR_RATIO; // 585.0
    private static final double WHEEL_DIAMETER_INCH = 2.3622; // 60 mm
    
    // The XRP has the left and right motors set to
    // channels 0 and 1 respectively
    private final XRPMotor leftMotor = new XRPMotor(0);
    private final XRPMotor rightMotor = new XRPMotor(1);
    
    // The XRP has onboard encoders that are hardcoded
    // to use DIO pins 4/5 and 6/7 for the left and right
    private final Encoder leftEncoder = new Encoder(4, 5);
    private final Encoder rightEncoder = new Encoder(6, 7);
    
    // Set up the differential drive controller
    private final DifferentialDrive diffDrive =
            new DifferentialDrive(leftMotor::set, rightMotor::set);
    
    // Set up the XRPGyro
    private final XRPGyro gyro = new XRPGyro();
    
    // Set up the BuiltInAccelerometer
    private final BuiltInAccelerometer accelerometer = new BuiltInAccelerometer();
    
    
    /** Creates a new Drivetrain. */
    public Drivetrain()
    {
        SendableRegistry.addChild(diffDrive, leftMotor);
        SendableRegistry.addChild(diffDrive, rightMotor);
        
        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightMotor.setInverted(true);
        
        // Use inches as unit for encoder distances
        leftEncoder.setDistancePerPulse((Math.PI * WHEEL_DIAMETER_INCH) / COUNTS_PER_REVOLUTION);
        rightEncoder.setDistancePerPulse((Math.PI * WHEEL_DIAMETER_INCH) / COUNTS_PER_REVOLUTION);
        resetEncoders();
    }
    
    
    public void arcadeDrive(double xAxisSpeed, double zAxisRotate)
    {
        diffDrive.arcadeDrive(xAxisSpeed, zAxisRotate);
    }
    
    
    public void resetEncoders()
    {
        leftEncoder.reset();
        rightEncoder.reset();
    }
    
    
    public int getLeftEncoderCount()
    {
        return leftEncoder.get();
    }
    
    
    public int getRightEncoderCount()
    {
        return rightEncoder.get();
    }
    
    
    public double getLeftDistanceInch()
    {
        return leftEncoder.getDistance();
    }
    
    
    public double getRightDistanceInch()
    {
        return rightEncoder.getDistance();
    }
    
    
    public double getAverageDistanceInch()
    {
        return (getLeftDistanceInch() + getRightDistanceInch()) / 2.0;
    }
    
    
    /**
     * The acceleration in the X-axis.
     *
     * @return The acceleration of the XRP along the X-axis in Gs
     */
    public double getAccelX()
    {
        return accelerometer.getX();
    }
    
    
    /**
     * The acceleration in the Y-axis.
     *
     * @return The acceleration of the XRP along the Y-axis in Gs
     */
    public double getAccelY()
    {
        return accelerometer.getY();
    }
    
    
    /**
     * The acceleration in the Z-axis.
     *
     * @return The acceleration of the XRP along the Z-axis in Gs
     */
    public double getAccelZ()
    {
        return accelerometer.getZ();
    }
    
    
    /**
     * Current angle of the XRP around the X-axis.
     *
     * @return The current angle of the XRP in degrees
     */
    public double getGyroAngleX()
    {
        return gyro.getAngleX();
    }
    
    
    /**
     * Current angle of the XRP around the Y-axis.
     *
     * @return The current angle of the XRP in degrees
     */
    public double getGyroAngleY()
    {
        return gyro.getAngleY();
    }
    
    
    /**
     * Current angle of the XRP around the Z-axis.
     *
     * @return The current angle of the XRP in degrees
     */
    public double getGyroAngleZ()
    {
        return gyro.getAngleZ();
    }
    
    
    /** Reset the gyro. */
    public void resetGyro()
    {
        gyro.reset();
    }
    
    
    @Override
    public void periodic()
    {
        // This method will be called once per scheduler run
    }
}
