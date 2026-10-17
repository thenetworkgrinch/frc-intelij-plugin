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

import org.wpilib.framework.TimesliceRobot
import org.wpilib.hardware.hal.HAL

/**
 * The functions in this object (which basically functions as a singleton class) are called automatically
 * corresponding to each mode, as described in the TimesliceRobot documentation.
 * This is written as an object rather than a class since there should only ever be a single instance, and
 * it cannot take any constructor arguments. This makes it a natural fit to be an object in Kotlin.
 *
 * If you change the name of this object or its package after creating this project, you must also update
 * the `Main.kt` file in the project. (If you use the IDE's Rename or Move refactorings when renaming the
 * object or package, it will get changed everywhere.)
 *
 * The call to the `TimesliceRobot(0.005, 0.01)` constructor runs the robot periodic() functions
 * for 5 ms, and runs controllers every 10 ms.
 */
object [=data.robotClassSimpleName] : TimesliceRobot(0.005, 0.01)
{
    init
    {
        // Kotlin initializer block, which effectually serves as the constructor code.
        // https://kotlinlang.org/docs/classes.html#constructors

        // Report the use of the Kotlin Language for "FRC Usage Report" statistics.
        // Please retain this line so that Kotlin's growing use by teams is seen by FRC/WPI.
        HAL.reportUsage("Language", "Kotlin")

        // Runs for 2 ms after robot periodic functions
        schedule({}, 0.002)

        // Runs for 2 ms after first controller function
        schedule({}, 0.002)

        // Total usage:
        // 5 ms (robot) + 2 ms (controller 1) + 2 ms (controller 2) = 9 ms
        // 9 ms / 10 ms -> 90% allocated
    }

    override fun robotPeriodic() {}

    override fun autonomousInit() {}

    override fun autonomousPeriodic() {}

    override fun teleopInit() {}

    override fun teleopPeriodic() {}

    override fun disabledInit() {}

    override fun disabledPeriodic() {}

    override fun utilityInit() {}

    override fun utilityPeriodic() {}
}
