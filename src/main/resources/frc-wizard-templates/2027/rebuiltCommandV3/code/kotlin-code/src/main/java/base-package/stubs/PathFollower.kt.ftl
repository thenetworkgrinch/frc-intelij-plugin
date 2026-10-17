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
package [=data.basePackage].stubs

import org.wpilib.math.kinematics.ChassisVelocities

/**
 * A stub interface for an API that could plausibly follow a path. No WPILib code exists for this;
 * if you want to follow paths on a real robot, use a third-party library provided by the FRC
 * programming community.
 */
interface PathFollower
{
    /**
     * Gets the next chassis velocities from the path.
     *
     * @return the next chassis velocities
     */
    fun next(): ChassisVelocities

    /** Whether the robot has reached the end of the path. */
    val isDone: Boolean

    companion object
    {
        /**
         * Loads a path from a file in the deploy directory. This is a stub implementation as an example;
         * a real robot program would use a third-party path following library.
         *
         * @param pathName The name of the path file to load.
         * @return A PathFollower instance that can follow the loaded path.
         */
        @Suppress("UNUSED_PARAMETER")
        fun load(pathName: String): PathFollower
        {
            return object : PathFollower
            {
                override fun next(): ChassisVelocities = ChassisVelocities()

                override val isDone: Boolean
                    get() = true
            }
        }
    }
}
