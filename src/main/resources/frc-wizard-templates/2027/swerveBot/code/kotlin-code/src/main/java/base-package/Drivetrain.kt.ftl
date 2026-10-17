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

import org.wpilib.hardware.imu.OnboardIMU
import org.wpilib.math.geometry.Translation2d
import org.wpilib.math.kinematics.ChassisVelocities
import org.wpilib.math.kinematics.SwerveDriveKinematics
import org.wpilib.math.kinematics.SwerveDriveOdometry

/** Represents a swerve drive style drivetrain. */
class Drivetrain
{
    companion object
    {
        const val MAX_VELOCITY = 3.0 // 3 meters per second
        const val MAX_ANGULAR_VELOCITY = Math.PI // 1/2 rotation per second
    }

    private val frontLeftLocation = Translation2d(0.381, 0.381)
    private val frontRightLocation = Translation2d(0.381, -0.381)
    private val backLeftLocation = Translation2d(-0.381, 0.381)
    private val backRightLocation = Translation2d(-0.381, -0.381)

    private val frontLeft = SwerveModule(1, 2, 0, 1, 2, 3)
    private val frontRight = SwerveModule(3, 4, 4, 5, 6, 7)
    private val backLeft = SwerveModule(5, 6, 8, 9, 10, 11)
    private val backRight = SwerveModule(7, 8, 12, 13, 14, 15)

    private val imu = OnboardIMU(OnboardIMU.MountOrientation.FLAT)

    private val kinematics =
        SwerveDriveKinematics(frontLeftLocation, frontRightLocation, backLeftLocation, backRightLocation)

    private val odometry = SwerveDriveOdometry(
        kinematics,
        imu.rotation2d,
        arrayOf(
            frontLeft.position,
            frontRight.position,
            backLeft.position,
            backRight.position
        )
    )

    init
    {
        imu.resetYaw()
    }

    /**
     * Method to drive the robot using joystick info.
     *
     * @param xVelocity Velocity of the robot in the x direction (forward).
     * @param yVelocity Velocity of the robot in the y direction (sideways).
     * @param rot Angular rate of the robot.
     * @param fieldRelative Whether the provided x and y velocities are relative to the field.
     */
    fun drive(xVelocity: Double, yVelocity: Double, rot: Double, fieldRelative: Boolean, period: Double)
    {
        var chassisVelocities = ChassisVelocities(xVelocity, yVelocity, rot)
        if (fieldRelative)
        {
            chassisVelocities = chassisVelocities.toRobotRelative(imu.rotation2d)
        }
        chassisVelocities = chassisVelocities.discretize(period)

        val velocities = SwerveDriveKinematics.desaturateWheelVelocities(
            kinematics.toWheelVelocities(chassisVelocities), MAX_VELOCITY
        )

        frontLeft.setDesiredVelocity(velocities[0])
        frontRight.setDesiredVelocity(velocities[1])
        backLeft.setDesiredVelocity(velocities[2])
        backRight.setDesiredVelocity(velocities[3])
    }

    /** Updates the field relative position of the robot. */
    fun updateOdometry()
    {
        odometry.update(
            imu.rotation2d,
            arrayOf(
                frontLeft.position,
                frontRight.position,
                backLeft.position,
                backRight.position
            )
        )
    }
}
