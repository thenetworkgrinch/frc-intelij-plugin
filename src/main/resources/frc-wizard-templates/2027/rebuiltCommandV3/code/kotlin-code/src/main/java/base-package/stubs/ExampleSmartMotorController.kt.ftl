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

/**
 * A simplified stub class that simulates the API of a common "smart" motor controller.
 *
 * Has no actual functionality.
 *
 * @param port The port for the controller.
 */
@Suppress("UNUSED_PARAMETER")
class ExampleSmartMotorController(port: Int)
{
    enum class PIDMode
    {
        POSITION,
        VELOCITY,
        MOVEMENT_WITCHCRAFT
    }

    internal var value = 0.0

    /**
     * Example function for setting the PID gains of the smart controller.
     *
     * @param kp The proportional gain.
     * @param ki The integral gain.
     * @param kd The derivative gain.
     */
    fun setPID(kp: Double, ki: Double, kd: Double) {}

    /**
     * Example function for setting the setpoint of the smart controller in PID mode.
     *
     * @param mode The mode of the PID controller.
     * @param setpoint The controller setpoint.
     */
    fun setSetpoint(mode: PIDMode, setpoint: Double) {}

    /**
     * Example function for setting the voltage supplied to the motor.
     *
     * @param volts How many volts to apply to the motor.
     */
    fun setVoltage(volts: Int) {}

    /**
     * Places this motor controller in follower mode.
     *
     * @param leader The leader to follow.
     */
    fun follow(leader: ExampleSmartMotorController) {}

    /**
     * Returns the encoder distance.
     *
     * @return The current encoder distance.
     */
    fun getEncoderDistance(): Double = 0.0

    /**
     * Returns the encoder rate.
     *
     * @return The current encoder rate.
     */
    fun getEncoderRate(): Double = 0.0

    /** Resets the encoder to zero distance. */
    fun resetEncoder() {}

    fun setThrottle(throttle: Double)
    {
        value = throttle
    }

    fun getThrottle(): Double = value

    fun setInverted(isInverted: Boolean) {}

    fun getInverted(): Boolean = false

    fun disable() {}

    fun stopMotor() {}
}
