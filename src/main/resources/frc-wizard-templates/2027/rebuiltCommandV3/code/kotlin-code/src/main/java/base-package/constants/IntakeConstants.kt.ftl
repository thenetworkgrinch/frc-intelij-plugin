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
package [=data.basePackage].constants

import org.wpilib.units.Units.Degrees
import org.wpilib.units.Units.RPM

import org.wpilib.units.measure.Angle
import org.wpilib.units.measure.AngularVelocity

object IntakeConstants
{
    const val ROLLER_MOTOR_ID = 20
    const val WRIST_MOTOR_ID = 21

    val WRIST_STOW_ANGLE: Angle = Degrees.of(90.0)
    val WRIST_DOWN_ANGLE: Angle = Degrees.of(-10.0)

    val WRIST_AGITATE_UP: Angle = Degrees.of(10.0)
    val WRIST_AGITATE_DOWN: Angle = WRIST_DOWN_ANGLE

    val ROLLER_INTAKE_SPEED: AngularVelocity = RPM.of(4000.0)
    val ROLLER_EXPULSION_SPEED: AngularVelocity = RPM.of(-3500.0)
}
