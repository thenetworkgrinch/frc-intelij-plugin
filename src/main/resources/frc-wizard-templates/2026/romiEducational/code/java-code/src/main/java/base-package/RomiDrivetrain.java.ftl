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

import edu.wpi.first.wpilibj.Encoder;
import edu.wpi.first.wpilibj.drive.DifferentialDrive;
import edu.wpi.first.wpilibj.motorcontrol.Spark;



public class RomiDrivetrain
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
    
    
    /** Creates a new RomiDrivetrain. */
    public RomiDrivetrain()
    {
        // Use inches as unit for encoder distances
        leftEncoder.setDistancePerPulse((Math.PI * WHEEL_DIAMETER_INCH) / COUNTS_PER_REVOLUTION);
        rightEncoder.setDistancePerPulse((Math.PI * WHEEL_DIAMETER_INCH) / COUNTS_PER_REVOLUTION);
        resetEncoders();
        
        // Invert right side since motor is flipped
        rightMotor.setInverted(true);
        
        // Disable motor safety
        diffDrive.setSafetyEnabled(false);
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
    
    
    public double getLeftDistanceInch()
    {
        return leftEncoder.getDistance();
    }
    
    
    public double getRightDistanceInch()
    {
        return rightEncoder.getDistance();
    }
}
