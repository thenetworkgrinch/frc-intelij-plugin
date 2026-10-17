<#ftl output_format="plainText" encoding="UTF-8">
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    Template Language Reference: https://freemarker.apache.org/docs/ref.html
    Template Author's Guide:     https://freemarker.apache.org/docs/dgui.html
-->
<#--  To DEBUG templates, set system property 'frc.freemarker.debug' to true when launching the testing instance of IntelliJ IDEA -->
</#compress>
${data.copyright}

package ${data.basePackage};

import org.wpilib.epilogue.Logged;
import ${data.basePackage}.constants.DriveConstants;
import org.wpilib.math.estimator.SwerveDrivePoseEstimator;
import org.wpilib.math.geometry.Pose2d;
import org.wpilib.math.geometry.Rotation2d;
import org.wpilib.math.kinematics.SwerveModulePosition;
import org.wpilib.math.shape.Rectangle2d;

@Logged
public class PoseEstimator {
  private final SwerveDrivePoseEstimator poseEstimator =
      new SwerveDrivePoseEstimator(
          DriveConstants.KINEMATICS,
          Rotation2d.ZERO,
          new SwerveModulePosition[] {
            new SwerveModulePosition(),
            new SwerveModulePosition(),
            new SwerveModulePosition(),
            new SwerveModulePosition()
          },
          Pose2d.ZERO);

  /**
   * Updates the pose estimator with the current gyro heading and swerve module positions.
   *
   * @param gyroHeading The current gyro heading
   * @param modulePositions The current module positions
   */
  public void odometryUpdate(Rotation2d gyroHeading, SwerveModulePosition... modulePositions) {
    poseEstimator.update(gyroHeading, modulePositions);
  }

  /**
   * Updates the pose estimator with a vision measurement.
   *
   * @param estimatedPose The estimated pose from vision
   * @param timestamp The timestamp of the vision measurement
   */
  public void visionUpdate(Pose2d estimatedPose, double timestamp) {
    poseEstimator.addVisionMeasurement(estimatedPose, timestamp);
  }

  /**
   * Returns the current estimated pose of the robot.
   *
   * @return The current estimated pose
   */
  public Pose2d getEstimatedPose() {
    return poseEstimator.getEstimatedPosition();
  }

  /**
   * Checks if the current estimated pose is within a given rectangular zone.
   *
   * @param bounds The rectangular zone to check against
   * @return True if the pose is within the zone, false otherwise
   */
  public boolean inZone(Rectangle2d bounds) {
    return bounds.contains(poseEstimator.getEstimatedPosition().getTranslation());
  }
}
