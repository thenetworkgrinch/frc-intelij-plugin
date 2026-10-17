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
import org.wpilib.math.numbers.N2
import org.wpilib.math.system.DCMotor
import org.wpilib.math.system.LinearSystem
import org.wpilib.math.system.LinearSystemLoop
import org.wpilib.math.system.Models
import org.wpilib.math.trajectory.TrapezoidProfile
import org.wpilib.math.util.Nat
import org.wpilib.math.util.Units

/**
 * This is a sample program to demonstrate how to use a state-space controller to control an arm.
 *
 * The robot is written as an object rather than a class since there should only ever be a single instance.
 */
object [=data.robotClassSimpleName] : TimedRobot()
{
    private const val MOTOR_PORT = 0
    private const val ENCODER_A_CHANNEL = 0
    private const val ENCODER_B_CHANNEL = 1
    private const val JOYSTICK_PORT = 0
    private val RAISED_POSITION = Units.degreesToRadians(90.0)
    private val LOWERED_POSITION = Units.degreesToRadians(0.0)

    // Moment of inertia of the arm, in kg * m^2. Can be estimated with CAD. If finding this constant
    // is difficult, LinearSystem.identifyPositionSystem may be better.
    private const val ARM_MOI = 1.2

    // Reduction between motors and encoder, as output over input. If the arm spins slower than
    // the motors, this number should be greater than one.
    private const val ARM_GEARING = 10.0

    private val profile = TrapezoidProfile(
        TrapezoidProfile.Constraints(
            Units.degreesToRadians(45.0),
            Units.degreesToRadians(90.0)
        )
    ) // Max arm velocity and acceleration.
    private var lastProfiledReference = TrapezoidProfile.State()

    // The plant holds a state-space model of our arm. This system has the following properties:
    //
    // States: [position, velocity], in radians and radians per second.
    // Inputs (what we can "put in"): [voltage], in volts.
    // Outputs (what we can measure): [position], in radians.
    private val armPlant: LinearSystem<N2, N1, N2> =
        Models.singleJointedArmFromPhysicalConstants(DCMotor.getNEO(2), ARM_MOI, ARM_GEARING)

    // The observer fuses our encoder data and voltage inputs to reject noise.
    @Suppress("UNCHECKED_CAST")
    private val observer: KalmanFilter<N2, N1, N1> = KalmanFilter(
        Nat.N2(),
        Nat.N1(),
        armPlant.slice(0) as LinearSystem<N2, N1, N1>,
        VecBuilder.fill(0.015, 0.17), // How accurate we
        // think our model is, in radians and radians/sec
        VecBuilder.fill(0.01), // How accurate we think our encoder position
        // data is. In this case we very highly trust our encoder position reading.
        0.020
    )

    // A LQR uses feedback to create voltage commands.
    @Suppress("UNCHECKED_CAST")
    private val controller: LinearQuadraticRegulator<N2, N1, N1> = LinearQuadraticRegulator(
        armPlant.slice(0) as LinearSystem<N2, N1, N1>,
        VecBuilder.fill(Units.degreesToRadians(1.0), Units.degreesToRadians(10.0)), // qelms.
        // Position and velocity error tolerances, in radians and radians per second. Decrease
        // this
        // to more heavily penalize state excursion, or make the controller behave more
        // aggressively. In this example we weight position much more highly than velocity, but
        // this
        // can be tuned to balance the two.
        VecBuilder.fill(12.0), // relms. Control effort (voltage) tolerance. Decrease this to more
        // heavily penalize control effort, or make the controller less aggressive. 12 is a good
        // starting point because that is the (approximate) maximum voltage of a battery.
        0.020
    ) // Nominal time between loops. 0.020 for TimedRobot, but can be

    // lower if using notifiers.

    // The state-space loop combines a controller, observer, feedforward and plant for easy control.
    @Suppress("UNCHECKED_CAST")
    private val loop: LinearSystemLoop<N2, N1, N1> =
        LinearSystemLoop(armPlant.slice(0) as LinearSystem<N2, N1, N1>, controller, observer, 12.0, 0.020)

    // An encoder set up to measure arm position in radians.
    private val encoder = Encoder(ENCODER_A_CHANNEL, ENCODER_B_CHANNEL)

    private val motor = PWMSparkMax(MOTOR_PORT)

    // A joystick to read the trigger from.
    private val joystick = Joystick(JOYSTICK_PORT)

    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        // We go 2 pi radians in 1 rotation, or 4096 counts.
        encoder.setDistancePerPulse(Math.PI * 2 / 4096.0)
    }

    override fun teleopInit()
    {
        // Reset our loop to make sure it's in a known state.
        loop.reset(VecBuilder.fill(encoder.distance, encoder.rate))

        // Reset our last reference to the current state.
        lastProfiledReference = TrapezoidProfile.State(encoder.distance, encoder.rate)
    }

    override fun teleopPeriodic()
    {
        // Sets the target position of our arm. This is similar to setting the setpoint of a
        // PID controller.
        val goal = if (joystick.trigger)
        {
            // the trigger is pressed, so we go to the high goal.
            TrapezoidProfile.State(RAISED_POSITION, 0.0)
        }
        else
        {
            // Otherwise, we go to the low goal
            TrapezoidProfile.State(LOWERED_POSITION, 0.0)
        }
        // Step our TrapezoidalProfile forward 20ms and set it as our next reference
        lastProfiledReference = profile.calculate(0.020, lastProfiledReference, goal)
        loop.setNextR(lastProfiledReference.position, lastProfiledReference.velocity)
        // Correct our Kalman filter's state vector estimate with encoder data.
        loop.correct(VecBuilder.fill(encoder.distance))

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
