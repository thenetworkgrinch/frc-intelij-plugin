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

object Constants
{
    const val MOTOR_PORT = 0
    const val ENCODER_A_CHANNEL = 0
    const val ENCODER_B_CHANNEL = 1
    const val JOYSTICK_PORT = 0

    const val ARM_POSITION_KEY = "ArmPosition"
    const val ARM_P_KEY = "ArmP"

    // The P gain for the PID controller that drives this arm.
    const val DEFAULT_ARM_KP = 50.0
    const val DEFAULT_ARM_SETPOINT_DEGREES = 75.0

    // distance per pulse = (angle per revolution) / (pulses per revolution)
    //  = (2 * PI rads) / (4096 pulses)
    const val ARM_ENCODER_DIST_PER_PULSE = 2.0 * Math.PI / 4096

    const val ARM_REDUCTION = 200.0
    const val ARM_MASS = 8.0 // Kilograms
    val ARM_LENGTH = Units.inchesToMeters(30.0)
    val MIN_ANGLE_RADS = Units.degreesToRadians(-75.0)
    val MAX_ANGLE_RADS = Units.degreesToRadians(255.0)
}
