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

import java.util.Optional
import org.wpilib.driverstation.Alliance
import org.wpilib.driverstation.internal.DriverStationBackend
import org.wpilib.math.geometry.Pose2d
import org.wpilib.math.geometry.Translation2d
import org.wpilib.math.shape.Rectangle2d

object FieldConstants
{
    // TODO: Measurements
    val RED_HUB_CENTER = Pose2d()
    val BLUE_HUB_CENTER = Pose2d()
    val NEUTRAL_ZONE = Rectangle2d(Translation2d(), Translation2d())
    val RED_ZONE = Rectangle2d(Translation2d(), Translation2d())
    val BLUE_ZONE = Rectangle2d(Translation2d(), Translation2d())

    /**
     * Gets location of our hub. Returns an empty optional if we don't have an alliance yet.
     *
     * @return The location of our hub.
     */
    fun targetHub(): Optional<Pose2d>
    {
        return DriverStationBackend.getAlliance()
            .map { a ->
                when (a)
                {
                    Alliance.RED -> RED_HUB_CENTER
                    Alliance.BLUE -> BLUE_HUB_CENTER
                }
            }
    }
}
