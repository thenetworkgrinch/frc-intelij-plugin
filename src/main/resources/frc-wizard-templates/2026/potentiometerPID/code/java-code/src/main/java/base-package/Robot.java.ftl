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
import edu.wpi.first.wpilibj.AnalogPotentiometer;
import edu.wpi.first.wpilibj.Joystick;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;



/**
 * This is a sample program to demonstrate how to use a soft potentiometer and a PID controller to
 * reach and maintain position setpoints on an elevator mechanism.
 */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    static final int POT_CHANNEL = 1;
    static final int MOTOR_CHANNEL = 7;
    static final int JOYSTICK_CHANNEL = 3;
    
    // The elevator can move 1.5 meters from top to bottom
    static final double FULL_HEIGHT_METERS = 1.5;
    
    // Bottom, middle, and top elevator setpoints
    static final double[] SETPOINTS_METERS = {0.2, 0.8, 1.4};
    
    // proportional, integral, and derivative speed constants
    // DANGER: when tuning PID constants, high/inappropriate values for P, I,
    // and D may cause dangerous, uncontrollable, or undesired behavior!
    private static final double P = 0.7;
    private static final double I = 0.35;
    private static final double D = 0.25;
    
    private final PIDController pidController = new PIDController(P, I, D);
    // Scaling is handled internally
    private final AnalogPotentiometer potentiometer =
            new AnalogPotentiometer(POT_CHANNEL, FULL_HEIGHT_METERS);
    private final PWMSparkMax elevatorMotor = new PWMSparkMax(MOTOR_CHANNEL);
    private final Joystick joystick = new Joystick(JOYSTICK_CHANNEL);
    
    private int index;
    
    
    @Override
    public void teleopInit()
    {
        // Move to the bottom setpoint when teleop starts
        index = 0;
        pidController.setSetpoint(SETPOINTS_METERS[index]);
    }
    
    
    @Override
    public void teleopPeriodic()
    {
        // Read from the sensor
        double position = potentiometer.get();
        
        // Run the PID Controller
        double pidOut = pidController.calculate(position);
        
        // Apply PID output
        elevatorMotor.set(pidOut);
        
        // when the button is pressed once, the selected elevator setpoint is incremented
        if (joystick.getTriggerPressed())
        {
            // index of the elevator setpoint wraps around.
            index = (index + 1) % SETPOINTS_METERS.length;
            System.out.println("index = " + index);
            pidController.setSetpoint(SETPOINTS_METERS[index]);
        }
    }
    
    
    @Override
    public void close()
    {
        elevatorMotor.close();
        potentiometer.close();
        pidController.close();
        index = 0;
        super.close();
    }
}
