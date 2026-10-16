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
import edu.wpi.first.wpilibj.motorcontrol.Spark;
import edu.wpi.first.wpilibj.romi.RomiGyro;
import edu.wpi.first.wpilibj2.command.SubsystemBase;



public class Drivetrain extends SubsystemBase
{
    private static final double COUNTS_PER_REVOLUTION = 1440.0;
    private static final double WHEEL_DIAMETER_INCH = 2.75591; // 70 mm
    
    // The Romi has the left and right motors set to
    // PWM channels 0 and 1 respectively
    private final Spark leftMotor = new Spark(0);
    private final Spark rightMotor = new Spark(1);
    
    // The Romi has onboard encoders that are hardcoded
    // to use DIO pins 4/5 and 6/7 for the left and right
    private final Encoder leftEncoder = new Encoder(4, 5);
    private final Encoder rightEncoder = new Encoder(6, 7);
    
    // Set up the differential drive controller
    private final DifferentialDrive diffDrive =
            new DifferentialDrive(leftMotor::set, rightMotor::set);
    
    // Set up the RomiGyro
    private final RomiGyro gyro = new RomiGyro();
    
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
     * @return The acceleration of the Romi along the X-axis in Gs
     */
    public double getAccelX()
    {
        return accelerometer.getX();
    }
    
    
    /**
     * The acceleration in the Y-axis.
     *
     * @return The acceleration of the Romi along the Y-axis in Gs
     */
    public double getAccelY()
    {
        return accelerometer.getY();
    }
    
    
    /**
     * The acceleration in the Z-axis.
     *
     * @return The acceleration of the Romi along the Z-axis in Gs
     */
    public double getAccelZ()
    {
        return accelerometer.getZ();
    }
    
    
    /**
     * Current angle of the Romi around the X-axis.
     *
     * @return The current angle of the Romi in degrees
     */
    public double getGyroAngleX()
    {
        return gyro.getAngleX();
    }
    
    
    /**
     * Current angle of the Romi around the Y-axis.
     *
     * @return The current angle of the Romi in degrees
     */
    public double getGyroAngleY()
    {
        return gyro.getAngleY();
    }
    
    
    /**
     * Current angle of the Romi around the Z-axis.
     *
     * @return The current angle of the Romi in degrees
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
