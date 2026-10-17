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
package [=data.basePackage]

import org.wpilib.drivers.motor.PWMSparkMax
import org.wpilib.driverstation.Joystick
import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL
import org.wpilib.hardware.rotation.Encoder
import org.wpilib.math.controller.LinearQuadraticRegulator
import org.wpilib.math.estimator.KalmanFilter
import org.wpilib.math.linalg.VecBuilder
import org.wpilib.math.numbers.N1
import org.wpilib.math.system.DCMotor
import org.wpilib.math.system.LinearSystem
import org.wpilib.math.system.LinearSystemLoop
import org.wpilib.math.system.Models
import org.wpilib.math.util.Nat
import org.wpilib.math.util.Units

/**
 * This is a sample program to demonstrate how to use a state-space controller to control a
 * flywheel.
 *
 * The robot is written as an object rather than a class since there should only ever be a single instance.
 */
object [=data.robotClassSimpleName] : TimedRobot()
{
    private const val MOTOR_PORT = 0
    private const val ENCODER_A_CHANNEL = 0
    private const val ENCODER_B_CHANNEL = 1
    private const val JOYSTICK_PORT = 0
    private val SPINUP_RAD_PER_SEC = Units.rotationsPerMinuteToRadiansPerSecond(500.0)

    private const val FLYWHEEL_MOMENT_OF_INERTIA = 0.00032 // kg * m^2

    // Reduction between motors and encoder, as output over input. If the flywheel spins slower than
    // the motors, this number should be greater than one.
    private const val FLYWHEEL_GEARING = 1.0

    // The plant holds a state-space model of our flywheel. This system has the following properties:
    //
    // States: [velocity], in radians per second.
    // Inputs (what we can "put in"): [voltage], in volts.
    // Outputs (what we can measure): [velocity], in radians per second.
    private val flywheelPlant: LinearSystem<N1, N1, N1> =
        Models.flywheelFromPhysicalConstants(DCMotor.getNEO(2), FLYWHEEL_MOMENT_OF_INERTIA, FLYWHEEL_GEARING)

    // The observer fuses our encoder data and voltage inputs to reject noise.
    private val observer: KalmanFilter<N1, N1, N1> = KalmanFilter(
        Nat.N1(),
        Nat.N1(),
        flywheelPlant,
        VecBuilder.fill(3.0), // How accurate we think our model is
        VecBuilder.fill(0.01), // How accurate we think our encoder
        // data is
        0.020
    )

    // A LQR uses feedback to create voltage commands.
    private val controller: LinearQuadraticRegulator<N1, N1, N1> = LinearQuadraticRegulator(
        flywheelPlant,
        VecBuilder.fill(8.0), // qelms. Velocity error tolerance, in radians per second. Decrease
        // this to more heavily penalize state excursion, or make the controller behave more
        // aggressively.
        VecBuilder.fill(12.0), // relms. Control effort (voltage) tolerance. Decrease this to more
        // heavily penalize control effort, or make the controller less aggressive. 12 is a good
        // starting point because that is the (approximate) maximum voltage of a battery.
        0.020
    ) // Nominal time between loops. 0.020 for TimedRobot, but can be
    // lower if using notifiers.

    // The state-space loop combines a controller, observer, feedforward and plant for easy control.
    private val loop: LinearSystemLoop<N1, N1, N1> = LinearSystemLoop(flywheelPlant, controller, observer, 12.0, 0.020)

    // An encoder set up to measure flywheel velocity in radians per second.
    private val encoder = Encoder(ENCODER_A_CHANNEL, ENCODER_B_CHANNEL)

    private val motor = PWMSparkMax(MOTOR_PORT)

    // A joystick to read the trigger from.
    private val joystick = Joystick(JOYSTICK_PORT)

    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        // We go 2 pi radians per 4096 clicks.
        encoder.setDistancePerPulse(2.0 * Math.PI / 4096.0)
    }

    override fun teleopInit()
    {
        loop.reset(VecBuilder.fill(encoder.rate))
    }

    override fun teleopPeriodic()
    {
        // Sets the target velocity of our flywheel. This is similar to setting the setpoint of a
        // PID controller.
        if (joystick.getTriggerPressed())
        {
            // We just pressed the trigger, so let's set our next reference
            loop.setNextR(VecBuilder.fill(SPINUP_RAD_PER_SEC))
        }
        else if (joystick.getTriggerReleased())
        {
            // We just released the trigger, so let's spin down
            loop.setNextR(VecBuilder.fill(0.0))
        }

        // Correct our Kalman filter's state vector estimate with encoder data.
        loop.correct(VecBuilder.fill(encoder.rate))

        // Update our LQR to generate new voltage commands and use the voltages to predict the next
        // state with out Kalman filter.
        loop.predict(0.020)

        // Send the new calculated voltage to the motors.
        // voltage = duty cycle * battery voltage, so
        // duty cycle = voltage / battery voltage
        val nextVoltage = loop.getU(0)
        motor.setVoltage(nextVoltage)
    }
}
