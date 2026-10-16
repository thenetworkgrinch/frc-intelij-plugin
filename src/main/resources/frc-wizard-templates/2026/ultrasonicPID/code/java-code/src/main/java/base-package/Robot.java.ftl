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

import edu.wpi.first.math.controller.PIDController;
import edu.wpi.first.math.filter.MedianFilter;
import edu.wpi.first.util.sendable.SendableRegistry;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.Ultrasonic;
import edu.wpi.first.wpilibj.drive.DifferentialDrive;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;



/**
 * This is a sample program to demonstrate the use of a PIDController with an ultrasonic sensor to
 * reach and maintain a set distance from an object.
 */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    // distance the robot wants to stay from an object
    // (one meter)
    static final double HOLD_DISTANCE_MILLIMETERS = 1.0e3;
    
    // proportional speed constant
    private static final double P = 0.001;
    // integral speed constant
    private static final double I = 0.0;
    // derivative speed constant
    private static final double D = 0.0;
    
    static final int LEFT_MOTOR_PORT = 0;
    static final int RIGHT_MOTOR_PORT = 1;
    
    static final int ULTRASONIC_PING_PORT = 0;
    static final int ULTRASONIC_ECHO_PORT = 1;
    
    // Ultrasonic sensors tend to be quite noisy and susceptible to sudden outliers,
    // so measurements are filtered with a 5-sample median filter
    private final MedianFilter filter = new MedianFilter(5);
    
    private final Ultrasonic ultrasonic = new Ultrasonic(ULTRASONIC_PING_PORT, ULTRASONIC_ECHO_PORT);
    private final PWMSparkMax leftMotor = new PWMSparkMax(LEFT_MOTOR_PORT);
    private final PWMSparkMax rightMotor = new PWMSparkMax(RIGHT_MOTOR_PORT);
    private final DifferentialDrive robotDrive =
            new DifferentialDrive(leftMotor::set, rightMotor::set);
    private final PIDController pidController = new PIDController(P, I, D);
    
    
    public Robot()
    {
        SendableRegistry.addChild(robotDrive, leftMotor);
        SendableRegistry.addChild(robotDrive, rightMotor);
    }
    
    
    @Override
    public void autonomousInit()
    {
        // Set setpoint of the pid controller
        pidController.setSetpoint(HOLD_DISTANCE_MILLIMETERS);
    }
    
    
    @Override
    public void autonomousPeriodic()
    {
        double measurement = ultrasonic.getRangeMM();
        double filteredMeasurement = filter.calculate(measurement);
        double pidOutput = pidController.calculate(filteredMeasurement);
        
        // disable input squaring -- PID output is linear
        robotDrive.arcadeDrive(pidOutput, 0, false);
    }
    
    
    @Override
    public void close()
    {
        leftMotor.close();
        rightMotor.close();
        ultrasonic.close();
        robotDrive.close();
        super.close();
    }
}
