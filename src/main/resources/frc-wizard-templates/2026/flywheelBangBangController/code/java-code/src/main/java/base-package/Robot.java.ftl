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

import edu.wpi.first.math.controller.BangBangController;
import edu.wpi.first.math.controller.SimpleMotorFeedforward;
import edu.wpi.first.math.numbers.N1;
import edu.wpi.first.math.system.LinearSystem;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.math.system.plant.LinearSystemId;
import edu.wpi.first.math.util.Units;
import edu.wpi.first.wpilibj.Encoder;
import edu.wpi.first.wpilibj.Joystick;
import edu.wpi.first.wpilibj.RobotController;
import edu.wpi.first.wpilibj.TimedRobot;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;
import edu.wpi.first.wpilibj.simulation.EncoderSim;
import edu.wpi.first.wpilibj.simulation.FlywheelSim;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;



/**
 * This is a sample program to demonstrate the use of a BangBangController with a flywheel to
 * control RPM.
 */
public class ${data.robotClassSimpleName} extends TimedRobot
{
    private static final int MOTOR_PORT = 0;
    private static final int ENCODER_A_CHANNEL = 0;
    private static final int ENCODER_B_CHANNEL = 1;
    
    // Max setpoint for joystick control in RPM
    private static final double MAX_SETPOINT_VALUE = 6000.0;
    
    // Joystick to control setpoint
    private final Joystick joystick = new Joystick(0);
    
    private final PWMSparkMax flywheelMotor = new PWMSparkMax(MOTOR_PORT);
    private final Encoder encoder = new Encoder(ENCODER_A_CHANNEL, ENCODER_B_CHANNEL);
    
    private final BangBangController bangBangController = new BangBangController();
    
    // Gains are for example purposes only - must be determined for your own robot!
    public static final double FLYWHEEL_KS = 0.0001; // V
    public static final double FLYWHEEL_KV = 0.000195; // V/RPM
    public static final double FLYWHEEL_KA = 0.0003; // V/(RPM/s)
    private final SimpleMotorFeedforward feedforward =
            new SimpleMotorFeedforward(FLYWHEEL_KS, FLYWHEEL_KV, FLYWHEEL_KA);
    
    // Simulation classes help us simulate our robot
    
    // Reduction between motors and encoder, as output over input. If the flywheel
    // spins slower than the motors, this number should be greater than one.
    private static final double FLYWHEEL_GEARING = 1.0;
    
    // 1/2 MR²
    private static final double FLYWHEEL_MOMENT_OF_INERTIA =
            0.5 * Units.lbsToKilograms(1.5) * Math.pow(Units.inchesToMeters(4), 2);
    
    private final DCMotor gearbox = DCMotor.getNEO(1);
    
    private final LinearSystem<N1, N1, N1> plant =
            LinearSystemId.createFlywheelSystem(gearbox, FLYWHEEL_GEARING, FLYWHEEL_MOMENT_OF_INERTIA);
    
    private final FlywheelSim flywheelSim = new FlywheelSim(plant, gearbox);
    private final EncoderSim encoderSim = new EncoderSim(encoder);
    
    
    public Robot()
    {
        // Add bang-bang controller to SmartDashboard and networktables.
        SmartDashboard.putData(bangBangController);
    }
    
    
    /** Controls flywheel to a set speed (RPM) controlled by a joystick. */
    @Override
    public void teleopPeriodic()
    {
        // Scale setpoint value between 0 and maxSetpointValue
        double setpoint =
                Math.max(
                        0.0,
                        joystick.getRawAxis(0)
                        * Units.rotationsPerMinuteToRadiansPerSecond(MAX_SETPOINT_VALUE));
        
        // Set setpoint and measurement of the bang-bang controller
        double bangOutput = bangBangController.calculate(encoder.getRate(), setpoint) * 12.0;
        
        // Controls a motor with the output of the BangBang controller and a
        // feedforward. The feedforward is reduced slightly to avoid overspeeding
        // the shooter.
        flywheelMotor.setVoltage(bangOutput + 0.9 * feedforward.calculate(setpoint));
    }
    
    
    /** Update our simulation. This should be run every robot loop in simulation. */
    @Override
    public void simulationPeriodic()
    {
        // To update our simulation, we set motor voltage inputs, update the
        // simulation, and write the simulated velocities to our simulated encoder
        flywheelSim.setInputVoltage(flywheelMotor.get() * RobotController.getInputVoltage());
        flywheelSim.update(0.02);
        encoderSim.setRate(flywheelSim.getAngularVelocityRadPerSec());
    }
}
