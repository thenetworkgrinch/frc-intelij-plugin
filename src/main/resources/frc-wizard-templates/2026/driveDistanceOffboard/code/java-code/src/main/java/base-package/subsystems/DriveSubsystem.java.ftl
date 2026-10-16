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

import edu.wpi.first.math.controller.SimpleMotorFeedforward;
import edu.wpi.first.math.trajectory.TrapezoidProfile;
import edu.wpi.first.math.trajectory.TrapezoidProfile.State;
import edu.wpi.first.util.sendable.SendableRegistry;
import edu.wpi.first.wpilibj.RobotController;
import edu.wpi.first.wpilibj.Timer;
import edu.wpi.first.wpilibj.drive.DifferentialDrive;
import ${data.basePackage}.Constants.DriveConstants;
import ${data.basePackage}.ExampleSmartMotorController;
import edu.wpi.first.wpilibj2.command.Command;
import edu.wpi.first.wpilibj2.command.SubsystemBase;



public class DriveSubsystem extends SubsystemBase
{
    // The motors on the left side of the drive.
    private final ExampleSmartMotorController leftLeader =
            new ExampleSmartMotorController(DriveConstants.LEFT_MOTOR_1_PORT);
    
    private final ExampleSmartMotorController leftFollower =
            new ExampleSmartMotorController(DriveConstants.LEFT_MOTOR_2_PORT);
    
    // The motors on the right side of the drive.
    private final ExampleSmartMotorController rightLeader =
            new ExampleSmartMotorController(DriveConstants.RIGHT_MOTOR_1_PORT);
    
    private final ExampleSmartMotorController rightFollower =
            new ExampleSmartMotorController(DriveConstants.RIGHT_MOTOR_2_PORT);
    
    // The feedforward controller.
    private final SimpleMotorFeedforward feedforward =
            new SimpleMotorFeedforward(
                    DriveConstants.ksVolts,
                    DriveConstants.kvVoltSecondsPerMeter,
                    DriveConstants.kaVoltSecondsSquaredPerMeter);
    
    // The robot's drive
    private final DifferentialDrive drive =
            new DifferentialDrive(leftLeader::set, rightLeader::set);
    
    // The trapezoid profile
    private final TrapezoidProfile profile =
            new TrapezoidProfile(
                    new TrapezoidProfile.Constraints(
                            DriveConstants.MAX_SPEED_METERS_PER_SECOND,
                            DriveConstants.MAX_ACCELERATION_METERS_PER_SECOND_SQUARED));
    
    // The timer
    private final Timer timer = new Timer();
    
    
    /** Creates a new DriveSubsystem. */
    public DriveSubsystem()
    {
        SendableRegistry.addChild(drive, leftLeader);
        SendableRegistry.addChild(drive, rightLeader);
        
        // We need to invert one side of the drivetrain so that positive voltages
        // result in both sides moving forward. Depending on how your robot's
        // gearbox is constructed, you might have to invert the left side instead.
        rightLeader.setInverted(true);
        
        leftFollower.follow(leftLeader);
        rightFollower.follow(rightLeader);
        
        leftLeader.setPID(DriveConstants.kp, 0, 0);
        rightLeader.setPID(DriveConstants.kp, 0, 0);
    }
    
    
    /**
     * Drives the robot using arcade controls.
     *
     * @param fwd      the commanded forward movement
     * @param rotation the commanded rotation
     */
    public void arcadeDrive(double fwd, double rotation)
    {
        drive.arcadeDrive(fwd, rotation);
    }
    
    
    /**
     * Attempts to follow the given drive states using offboard PID.
     *
     * @param currentLeft  The current left wheel state.
     * @param currentRight The current right wheel state.
     * @param nextLeft     The next left wheel state.
     * @param nextRight    The next right wheel state.
     */
    public void setDriveStates(
            TrapezoidProfile.State currentLeft,
            TrapezoidProfile.State currentRight,
            TrapezoidProfile.State nextLeft,
            TrapezoidProfile.State nextRight)
    {
        // Feedforward is divided by battery voltage to normalize it to [-1, 1]
        leftLeader.setSetpoint(
                ExampleSmartMotorController.PIDMode.Position,
                currentLeft.position,
                feedforward.calculateWithVelocities(currentLeft.velocity, nextLeft.velocity)
                / RobotController.getBatteryVoltage());
        rightLeader.setSetpoint(
                ExampleSmartMotorController.PIDMode.Position,
                currentRight.position,
                feedforward.calculateWithVelocities(currentLeft.velocity, nextLeft.velocity)
                / RobotController.getBatteryVoltage());
    }
    
    
    /**
     * Returns the left encoder distance.
     *
     * @return the left encoder distance
     */
    public double getLeftEncoderDistance()
    {
        return leftLeader.getEncoderDistance();
    }
    
    
    /**
     * Returns the right encoder distance.
     *
     * @return the right encoder distance
     */
    public double getRightEncoderDistance()
    {
        return rightLeader.getEncoderDistance();
    }
    
    
    /** Resets the drive encoders. */
    public void resetEncoders()
    {
        leftLeader.resetEncoder();
        rightLeader.resetEncoder();
    }
    
    
    /**
     * Sets the max output of the drive. Useful for scaling the drive to drive more slowly.
     *
     * @param maxOutput the maximum output to which the drive will be constrained
     */
    public void setMaxOutput(double maxOutput)
    {
        drive.setMaxOutput(maxOutput);
    }
    
    
    /**
     * Creates a command to drive forward a specified distance using a motion profile.
     *
     * @param distance The distance to drive forward.
     *
     * @return A command.
     */
    public Command profiledDriveDistance(double distance)
    {
        return startRun(
                () -> {
                    // Restart timer so profile setpoints start at the beginning
                    timer.restart();
                    resetEncoders();
                },
                () -> {
                    // Current state never changes, so we need to use a timer to get the setpoints we need
                    // to be at
                    var currentTime = timer.get();
                    var currentSetpoint =
                            profile.calculate(currentTime, new State(), new State(distance, 0));
                    var nextSetpoint =
                            profile.calculate(
                                    currentTime + DriveConstants.DT, new State(), new State(distance, 0));
                    setDriveStates(currentSetpoint, currentSetpoint, nextSetpoint, nextSetpoint);
                })
                .until(() -> profile.isFinished(0));
    }
    
    
    private double initialLeftDistance;
    private double initialRightDistance;
    
    
    /**
     * Creates a command to drive forward a specified distance using a motion profile without
     * resetting the encoders.
     *
     * @param distance The distance to drive forward.
     *
     * @return A command.
     */
    public Command dynamicProfiledDriveDistance(double distance)
    {
        return startRun(
                () -> {
                    // Restart timer so profile setpoints start at the beginning
                    timer.restart();
                    // Store distance so we know the target distance for each encoder
                    initialLeftDistance = getLeftEncoderDistance();
                    initialRightDistance = getRightEncoderDistance();
                },
                () -> {
                    // Current state never changes for the duration of the command, so we need to use a
                    // timer to get the setpoints we need to be at
                    var currentTime = timer.get();
                    var currentLeftSetpoint =
                            profile.calculate(
                                    currentTime,
                                    new State(initialLeftDistance, 0),
                                    new State(initialLeftDistance + distance, 0));
                    var currentRightSetpoint =
                            profile.calculate(
                                    currentTime,
                                    new State(initialRightDistance, 0),
                                    new State(initialRightDistance + distance, 0));
                    var nextLeftSetpoint =
                            profile.calculate(
                                    currentTime + DriveConstants.DT,
                                    new State(initialLeftDistance, 0),
                                    new State(initialLeftDistance + distance, 0));
                    var nextRightSetpoint =
                            profile.calculate(
                                    currentTime + DriveConstants.DT,
                                    new State(initialRightDistance, 0),
                                    new State(initialRightDistance + distance, 0));
                    setDriveStates(
                            currentLeftSetpoint, currentRightSetpoint, nextLeftSetpoint, nextRightSetpoint);
                })
                .until(() -> profile.isFinished(0));
    }
}
