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

package ${data.basePackage}.constants;

import java.util.Optional;
import org.wpilib.driverstation.internal.DriverStationBackend;
import org.wpilib.math.geometry.Pose2d;
import org.wpilib.math.geometry.Translation2d;
import org.wpilib.math.shape.Rectangle2d;

public final class FieldConstants {
  // TODO: Measurements
  public static final Pose2d RED_HUB_CENTER = new Pose2d();
  public static final Pose2d BLUE_HUB_CENTER = new Pose2d();
  public static final Rectangle2d NEUTRAL_ZONE =
      new Rectangle2d(new Translation2d(), new Translation2d());
  public static final Rectangle2d RED_ZONE =
      new Rectangle2d(new Translation2d(), new Translation2d());
  public static final Rectangle2d BLUE_ZONE =
      new Rectangle2d(new Translation2d(), new Translation2d());

  /**
   * Gets location of our hub. Returns an empty optional if we don't have an alliance yet.
   *
   * @return The location of our hub.
   */
  public static Optional<Pose2d> targetHub() {
    return DriverStationBackend.getAlliance()
        .map(
            a -> {
              return switch (a) {
                case RED -> RED_HUB_CENTER;
                case BLUE -> BLUE_HUB_CENTER;
              };
            });
  }
}
