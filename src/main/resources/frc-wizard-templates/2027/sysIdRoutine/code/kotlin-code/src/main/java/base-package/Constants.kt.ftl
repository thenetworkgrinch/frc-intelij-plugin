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

import org.wpilib.math.util.Units

/**
 * The Constants object provides a convenient place for teams to hold robot-wide numerical or boolean
 * constants. This object should not be used for any other purpose. All String, Boolean, and numeric
 * (Int, Long, Float, Double) constants should use `const` definitions. Other constant types should use
 * `val` definitions. Do not put anything functional in this object.
 *
 * It is advised to import this object (or one of its nested objects) wherever the
 * constants are needed, to reduce verbosity.
 */
object Constants
{
    object DriveConstants
    {
        const val LEFT_MOTOR1_PORT = 0
        const val LEFT_MOTOR2_PORT = 1
        const val RIGHT_MOTOR1_PORT = 2
        const val RIGHT_MOTOR2_PORT = 3

        val LEFT_ENCODER_PORTS = intArrayOf(0, 1)
        val RIGHT_ENCODER_PORTS = intArrayOf(2, 3)
        const val LEFT_ENCODER_REVERSED = false
        const val RIGHT_ENCODER_REVERSED = true

        const val ENCODER_CPR = 1024
        val WHEEL_DIAMETER = Units.inchesToMeters(6.0)
        val ENCODER_DISTANCE_PER_PULSE =
            // Assumes the encoders are directly mounted on the wheel shafts
            (WHEEL_DIAMETER * Math.PI) / ENCODER_CPR
    }

    object ShooterConstants
    {
        val ENCODER_PORTS = intArrayOf(4, 5)
        const val ENCODER_REVERSED = false
        const val ENCODER_CPR = 1024
        const val ENCODER_DISTANCE_PER_PULSE =
            // Distance units will be rotations
            1.0 / ENCODER_CPR

        const val SHOOTER_MOTOR_PORT = 4
        const val FEEDER_MOTOR_PORT = 5

        const val SHOOTER_FREE_RPS = 5300.0
        const val SHOOTER_TARGET_RPS = 4000.0
        const val SHOOTER_TOLERANCE_RPS = 50.0

        // These are not real PID gains, and will have to be tuned for your specific robot.
        const val kP = 1.0

        // On a real robot the feedforward constants should be empirically determined; these are
        // reasonable guesses.
        const val kS = 0.05 // V
        // Should have value 12V at free speed
        const val kV = 12.0 / SHOOTER_FREE_RPS // V/(rot/s)
        const val kA = 0.0 // V/(rot/s²)

        const val FEEDER_VELOCITY = 0.5
    }

    object IntakeConstants
    {
        const val MOTOR_PORT = 6
        val SOLENOID_PORTS = intArrayOf(2, 3)
    }

    object StorageConstants
    {
        const val MOTOR_PORT = 7
        const val BALL_SENSOR_PORT = 6
    }

    object AutoConstants
    {
        const val TIMEOUT = 3.0
        const val DRIVE_DISTANCE = 2.0 // m
        const val DRIVE_VELOCITY = 0.5
    }

    object OIConstants
    {
        const val DRIVER_CONTROLLER_PORT = 0
    }
}
