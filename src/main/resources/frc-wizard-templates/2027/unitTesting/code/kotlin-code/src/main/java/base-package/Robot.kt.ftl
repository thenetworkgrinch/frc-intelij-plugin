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

import [=data.basePackage].Constants.IntakeConstants
import [=data.basePackage].subsystems.Intake
import org.wpilib.driverstation.Joystick
import org.wpilib.framework.TimedRobot
import org.wpilib.hardware.hal.HAL

/**
 * The functions in this object (which basically functions as a singleton class) are called automatically
 * corresponding to each mode, as described in the TimedRobot documentation. If you change the name of
 * this object or the package after creating this project, you must also update the `Main.kt` file in the project.
 */
object [=data.robotClassSimpleName] : TimedRobot()
{
    private val intake = Intake()
    private val joystick = Joystick(Constants.JOYSTICK_INDEX)

    init
    {
        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")
    }

    /** This method is called periodically during operator control. */
    override fun teleopPeriodic()
    {
        // Activate the intake while the trigger is held
        if (joystick.trigger)
        {
            intake.activate(IntakeConstants.INTAKE_VELOCITY)
        }
        else
        {
            intake.activate(0.0)
        }

        // Toggle deploying the intake when the top button is pressed
        if (joystick.top)
        {
            if (intake.isDeployed)
            {
                intake.retract()
            }
            else
            {
                intake.deploy()
            }
        }
    }
}
