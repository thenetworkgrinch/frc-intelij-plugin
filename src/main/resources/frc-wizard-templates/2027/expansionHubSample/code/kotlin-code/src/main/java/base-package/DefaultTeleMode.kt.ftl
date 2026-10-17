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

import org.wpilib.driverstation.DriverStation
import org.wpilib.driverstation.Gamepad
import org.wpilib.opmode.PeriodicOpMode
import org.wpilib.opmode.Teleop

@Teleop
class DefaultTeleMode(private val robot: [=data.robotClassSimpleName]) : PeriodicOpMode()
{
    private val gamepad: Gamepad = DriverStation.getGamepad(0)

    override fun periodic()
    {
        robot.motor0.setThrottle(-gamepad.leftY)
        robot.motor1.setThrottle(-gamepad.rightY)
        robot.motor2.setThrottle(-gamepad.leftX)
        robot.motor3.setThrottle(-gamepad.rightX)
        robot.servo0.setPosition(gamepad.leftTrigger)
        robot.servo1.setPosition(gamepad.rightTrigger)
    }
}
