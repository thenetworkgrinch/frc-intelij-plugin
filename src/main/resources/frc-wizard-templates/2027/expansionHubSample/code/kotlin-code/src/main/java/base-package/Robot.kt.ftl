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

import org.wpilib.framework.OpModeRobot
import org.wpilib.hardware.expansionhub.ExpansionHubMotor
import org.wpilib.hardware.expansionhub.ExpansionHubServo
import org.wpilib.hardware.hal.HAL

/**
 * This is a demo program showing the use of the Expansion Hub motors and servos. The motors and
 * servos are driven using the controllers in the telop opmode, and timed in the auto op mode.
 *
 * This is written as an object rather than a class since there should only ever be a single
 * robot instance. If you change the name of this object or its package after creating this
 * project, you must also update the `Main.kt` file in the project.
 */
object [=data.robotClassSimpleName] : OpModeRobot()
{
    val motor0 = ExpansionHubMotor(0, 0)
    val motor1 = ExpansionHubMotor(0, 1)
    val motor2 = ExpansionHubMotor(0, 2)
    val motor3 = ExpansionHubMotor(0, 3)

    val servo0 = ExpansionHubServo(0, 0)
    val servo1 = ExpansionHubServo(0, 1)

    /** Called once at the beginning of the robot program. */
    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")
    }
}
