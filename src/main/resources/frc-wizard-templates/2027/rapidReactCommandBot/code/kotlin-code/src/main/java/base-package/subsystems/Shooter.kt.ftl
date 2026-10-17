<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    IMPORTANT: This template uses alternate square bracket interpolation syntax
               For example:
                    [=data.robotClassSimpleName]
               rather than:
                    ${data.robotClassSimpleName}
               so as to not clash with Kotlin string templates syntax
               The option to use that can't be set in the template, but has to be set as an
               option on the Configuration object in the code. Note that this only affects interpolation
               syntax, and *NOT* Tag syntax. So we will still use `<#if isSuchAndSuch>` and not `[#if isSuchAndSuch]`.
               Tag syntax can be changed if desired, but we are not.
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
package [=data.basePackage].subsystems

import org.wpilib.epilogue.Logged
import org.wpilib.command2.Command
import org.wpilib.command2.Commands.parallel
import org.wpilib.command2.Commands.waitUntil
import org.wpilib.command2.SubsystemBase
import org.wpilib.drivers.motor.PWMSparkMax
import [=data.basePackage].Constants.ShooterConstants
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.math.controller.PIDController
import org.wpilib.math.controller.SimpleMotorFeedforward

@Logged
class Shooter : SubsystemBase()
{
    private val shooterMotor = PWMSparkMax(ShooterConstants.SHOOTER_MOTOR_PORT)
    private val feederMotor = PWMSparkMax(ShooterConstants.FEEDER_MOTOR_PORT)
    private val shooterEncoder = Encoder(
        ShooterConstants.ENCODER_PORTS[0],
        ShooterConstants.ENCODER_PORTS[1],
        ShooterConstants.ENCODER_REVERSED)
    private val shooterFeedforward = SimpleMotorFeedforward(ShooterConstants.kS, ShooterConstants.kV)
    private val shooterFeedback = PIDController(ShooterConstants.kP, 0.0, 0.0)

    /** The shooter subsystem for the robot. */
    init
    {
        shooterFeedback.setTolerance(ShooterConstants.SHOOTER_TOLERANCE_RPS)
        shooterEncoder.distancePerPulse = ShooterConstants.ENCODER_DISTANCE_PER_PULSE

        // Set default command to turn off both the shooter and feeder motors, and then idle
        defaultCommand =
            runOnce {
                    shooterMotor.throttle = 0.0
                    feederMotor.throttle = 0.0
                }
                .andThen(run {})
                .withName("Idle")
    }

    /**
     * Returns a command to shoot the balls currently stored in the robot. Spins the shooter flywheel
     * up to the specified setpoint, and then runs the feeder motor.
     *
     * @param setpointRotationsPerSecond The desired shooter velocity
     */
    fun shootCommand(setpointRotationsPerSecond: Double): Command =
        parallel(
            // Run the shooter flywheel at the desired setpoint using feedforward and feedback
            run {
                shooterMotor.throttle =
                    shooterFeedforward.calculate(setpointRotationsPerSecond) +
                        shooterFeedback.calculate(shooterEncoder.rate, setpointRotationsPerSecond)
            },

            // Wait until the shooter has reached the setpoint, and then run the feeder
            waitUntil(shooterFeedback::atSetpoint).andThen({ feederMotor.throttle = 1.0 }))
            .withName("Shoot")
}
