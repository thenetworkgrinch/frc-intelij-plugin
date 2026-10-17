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

import org.wpilib.epilogue.Logged
import [=data.basePackage].constants.DriveConstants
import org.wpilib.math.estimator.SwerveDrivePoseEstimator
import org.wpilib.math.geometry.Pose2d
import org.wpilib.math.geometry.Rotation2d
import org.wpilib.math.kinematics.SwerveModulePosition
import org.wpilib.math.shape.Rectangle2d

@Logged
class PoseEstimator
{
    private val poseEstimator = SwerveDrivePoseEstimator(
        DriveConstants.KINEMATICS,
        Rotation2d.ZERO,
        arrayOf(
            SwerveModulePosition(),
            SwerveModulePosition(),
            SwerveModulePosition(),
            SwerveModulePosition()
        ),
        Pose2d.ZERO)

    /**
     * Updates the pose estimator with the current gyro heading and swerve module positions.
     *
     * @param gyroHeading The current gyro heading
     * @param modulePositions The current module positions
     */
    fun odometryUpdate(gyroHeading: Rotation2d, vararg modulePositions: SwerveModulePosition)
    {
        poseEstimator.update(gyroHeading, modulePositions)
    }

    /**
     * Updates the pose estimator with a vision measurement.
     *
     * @param estimatedPose The estimated pose from vision
     * @param timestamp The timestamp of the vision measurement
     */
    fun visionUpdate(estimatedPose: Pose2d, timestamp: Double)
    {
        poseEstimator.addVisionMeasurement(estimatedPose, timestamp)
    }

    /** The current estimated pose of the robot. */
    val estimatedPose: Pose2d
        get() = poseEstimator.estimatedPosition

    /**
     * Checks if the current estimated pose is within a given rectangular zone.
     *
     * @param bounds The rectangular zone to check against
     * @return True if the pose is within the zone, false otherwise
     */
    fun inZone(bounds: Rectangle2d): Boolean
    {
        return bounds.contains(poseEstimator.estimatedPosition.translation)
    }
}
