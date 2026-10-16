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

import edu.wpi.first.math.controller.ElevatorFeedforward;
import edu.wpi.first.math.controller.ProfiledPIDController;
import edu.wpi.first.math.system.plant.DCMotor;
import edu.wpi.first.math.trajectory.TrapezoidProfile;
import edu.wpi.first.wpilibj.Encoder;
import edu.wpi.first.wpilibj.RobotController;
import ${data.basePackage}.Constants;
import edu.wpi.first.wpilibj.motorcontrol.PWMSparkMax;
import edu.wpi.first.wpilibj.simulation.BatterySim;
import edu.wpi.first.wpilibj.simulation.ElevatorSim;
import edu.wpi.first.wpilibj.simulation.EncoderSim;
import edu.wpi.first.wpilibj.simulation.PWMSim;
import edu.wpi.first.wpilibj.simulation.RoboRioSim;
import edu.wpi.first.wpilibj.smartdashboard.Mechanism2d;
import edu.wpi.first.wpilibj.smartdashboard.MechanismLigament2d;
import edu.wpi.first.wpilibj.smartdashboard.MechanismRoot2d;
import edu.wpi.first.wpilibj.smartdashboard.SmartDashboard;



public class Elevator implements AutoCloseable
{
    // This gearbox represents a gearbox containing 4 Vex 775pro motors.
    private final DCMotor elevatorGearbox = DCMotor.getVex775Pro(4);
    
    // Standard classes for controlling our elevator
    private final ProfiledPIDController controller =
            new ProfiledPIDController(
                    Constants.ELEVATOR_KP,
                    Constants.ELEVATOR_KI,
                    Constants.ELEVATOR_KD,
                    new TrapezoidProfile.Constraints(2.45, 2.45));
    ElevatorFeedforward feedforward =
            new ElevatorFeedforward(
                    Constants.ELEVATORK_S,
                    Constants.ELEVATORK_G,
                    Constants.ELEVATORK_V,
                    Constants.ELEVATORK_A);
    private final Encoder encoder =
            new Encoder(Constants.ENCODER_A_CHANNEL, Constants.ENCODER_B_CHANNEL);
    private final PWMSparkMax motor = new PWMSparkMax(Constants.MOTOR_PORT);
    
    // Simulation classes help us simulate what's going on, including gravity.
    private final ElevatorSim elevatorSim =
            new ElevatorSim(
                    elevatorGearbox,
                    Constants.ELEVATOR_GEARING,
                    Constants.CARRIAGE_MASS,
                    Constants.ELEVATOR_DRUM_RADIUS,
                    Constants.MIN_ELEVATOR_HEIGHT_METERS,
                    Constants.MAX_ELEVATOR_HEIGHT_METERS,
                    true,
                    0,
                    0.01,
                    0.0);
    private final EncoderSim encoderSim = new EncoderSim(encoder);
    private final PWMSim motorSim = new PWMSim(motor);
    
    // Create a Mechanism2d visualization of the elevator
    private final Mechanism2d mech2d = new Mechanism2d(20, 50);
    private final MechanismRoot2d mech2dRoot = mech2d.getRoot("Elevator Root", 10, 0);
    private final MechanismLigament2d elevatorMech2d =
            mech2dRoot.append(
                    new MechanismLigament2d("Elevator", elevatorSim.getPositionMeters(), 90));
    
    
    /** Subsystem constructor. */
    public Elevator()
    {
        encoder.setDistancePerPulse(Constants.ELEVATOR_ENCODER_DIST_PER_PULSE);
        
        // Publish Mechanism2d to SmartDashboard
        // To view the Elevator visualization, select Network Tables -> SmartDashboard -> Elevator Sim
        SmartDashboard.putData("Elevator Sim", mech2d);
    }
    
    
    /** Advance the simulation. */
    public void simulationPeriodic()
    {
        // In this method, we update our simulation of what our elevator is doing
        // First, we set our "inputs" (voltages)
        elevatorSim.setInput(motorSim.getSpeed() * RobotController.getBatteryVoltage());
        
        // Next, we update it. The standard loop time is 20ms.
        elevatorSim.update(0.020);
        
        // Finally, we set our simulated encoder's readings and simulated battery voltage
        encoderSim.setDistance(elevatorSim.getPositionMeters());
        // SimBattery estimates loaded battery voltages
        RoboRioSim.setVInVoltage(
                BatterySim.calculateDefaultBatteryLoadedVoltage(elevatorSim.getCurrentDrawAmps()));
    }
    
    
    /**
     * Run control loop to reach and maintain goal.
     *
     * @param goal the position to maintain
     */
    public void reachGoal(double goal)
    {
        controller.setGoal(goal);
        
        // With the setpoint value we run PID control like normal
        double pidOutput = controller.calculate(encoder.getDistance());
        double feedforwardOutput = feedforward.calculate(controller.getSetpoint().velocity);
        motor.setVoltage(pidOutput + feedforwardOutput);
    }
    
    
    /** Stop the control loop and motor output. */
    public void stop()
    {
        controller.setGoal(0.0);
        motor.set(0.0);
    }
    
    
    /** Update telemetry, including the mechanism visualization. */
    public void updateTelemetry()
    {
        // Update elevator visualization with position
        elevatorMech2d.setLength(encoder.getDistance());
    }
    
    
    @Override
    public void close()
    {
        encoder.close();
        motor.close();
        mech2d.close();
    }
}
