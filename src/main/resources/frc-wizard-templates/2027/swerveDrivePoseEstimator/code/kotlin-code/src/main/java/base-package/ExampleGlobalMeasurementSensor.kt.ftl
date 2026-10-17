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

import org.wpilib.math.geometry.Pose2d
import org.wpilib.math.geometry.Rotation2d
import org.wpilib.math.linalg.VecBuilder
import org.wpilib.math.random.Normal
import org.wpilib.math.util.Units

/** This dummy object represents a global measurement sensor, such as a computer vision solution. */
object ExampleGlobalMeasurementSensor
{
    /**
     * Get a "noisy" fake global pose reading.
     *
     * @param estimatedRobotPose The robot pose.
     */
    fun getEstimatedGlobalPose(estimatedRobotPose: Pose2d): Pose2d
    {
        val rand = Normal.normal(VecBuilder.fill(0.5, 0.5, Units.degreesToRadians(30.0)))
        return Pose2d(
            estimatedRobotPose.x + rand.get(0, 0),
            estimatedRobotPose.y + rand.get(1, 0),
            estimatedRobotPose.rotation.plus(Rotation2d(rand.get(2, 0)))
        )
    }
}
