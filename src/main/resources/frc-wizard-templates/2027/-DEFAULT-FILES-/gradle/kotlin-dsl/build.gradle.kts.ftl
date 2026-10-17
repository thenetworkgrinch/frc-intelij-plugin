<#ftl output_format="plainText" encoding="UTF-8"> <#-- Output formats: https://freemarker.apache.org/docs/dgui_misc_autoescaping.html -->
<#--noinspection WrongPackageStatement-->
<#compress>
<#-- @ftlvariable name="data" type="net.javaru.iip.frc.wizard.FrcProjectWizardData" -->
<#--
    IMPORTANT: This tempolate uses alternate square bracket interpolation syntax
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

<#if data.isSystemCoreRobotTemplate()>
import org.wpilib.deployutils.deploy.artifact.FileTreeArtifact
import org.wpilib.gradlerio.deploy.systemcore.SystemCore
import org.wpilib.gradlerio.deploy.systemcore.WPILibJavaArtifact
</#if>
import org.wpilib.toolchain.NativePlatforms
import org.gradle.plugins.ide.idea.model.IdeaLanguageLevel
<#if data.getIncludeKotlinSupport()>
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
</#if>

/*
    == D I S C L A I M E R ==
    Using Kotlin DSL for Gradle builds is not officially supported by FRC/WPILib.
    As such, by using the Kotlin DSL, you acknowledge that you will not receive any support from the WPI Lib team,
    and support from the community will likely be very limited. There are known issues with using Kotlin DSL Gradle
    files in VS Code. As such, if you have team members using VS Code, use of the Kotlin DSL is not recommended.
    The use of Kotlin DSL is only recommend for developers experienced with the Gradle Kotlin DSL.
    (This disclaimer is included at the request of the WPI Lib development team.)
 */

plugins {
    java
    application
<#if data.getIncludeKotlinSupport()>
    kotlin("jvm") version "[=data.kotlinPluginVersion]"
    // kapt runs WPILib's annotation processors (such as Epilogue's) over the Kotlin and Java code
    kotlin("kapt") version "[=data.kotlinPluginVersion]"
</#if>
    id("org.wpilib.GradleRIO") version "[=data.wpilibVersion.versionString]"
    idea
}


val javaVersion: JavaVersion by extra { JavaVersion.VERSION_25 }
val javaLanguageVersion: JavaLanguageVersion by extra { JavaLanguageVersion.of(javaVersion.toString()) }
<#if data.getIncludeKotlinSupport()>
val kotlinJvmTarget: JvmTarget = JvmTarget.fromTarget(javaVersion.toString())
</#if>

@Suppress("PropertyName")
val ROBOT_MAIN_CLASS = "[=data.mainClassFQ]"

<#if data.isSystemCoreRobotTemplate()>
// Define my targets (SystemCore) and artifacts (deployable files)
// This is added by GradleRIO's backing project DeployUtils.
deploy {
    targets {
        val systemcore by register<SystemCore>("systemcore") {
            // Team number is loaded either from the .wpilib/wpilib_preferences.json
            // or from command line. If not found an exception will be thrown.
            // You can use wpilib.getTeamOrDefault(####) instead of wpilib.teamNumber
            // if you want to store a team number in this file.
            team = wpilib.teamNumber
            // Use the default systemcore host name. This must be called after setting team
            // as happens on the line above
            useDefaultSystemcoreHostName()
            debug = wpilib.getDebugOrDefault(false)
        }

        systemcore.artifacts {
            register<WPILibJavaArtifact>("wpilibJava") {
                // Set to true to use debug including JNI, which will drastically impact performance.
                debugJni.set(false)
            }

            register<FileTreeArtifact>("wpilibStaticFileDeploy") {
                files = project.fileTree("src/main/deploy")
                directory = "/home/systemcore/deploy"
                // Change to true to delete files on systemcore that no longer exist in deploy directory of this project
                deleteOldFiles = false
            }
        }
    }
}

val deployArtifact = deploy.targets.getByName("systemcore").artifacts.getByName("wpilibJava") as WPILibJavaArtifact

</#if>
application {
    mainClass = ROBOT_MAIN_CLASS
}

wpi {
    with(java) {
<#if data.isSystemCoreRobotTemplate()>
        // Set to true to use debug for simulation including JNI
        runSimWithDebugJni.set(false)
</#if>
        configureApplication(application)
        configureTestTasks(tasks.test.get())
    }

    // Simulation configuration (e.g. environment variables).
    with(sim) {
        addGui().apply {
            defaultEnabled = true
        }
        addDriverstation()
<#if data.isRomiTemplate()>

        //Sets the websocket client remote host.
        //envVar("HALSIMWS_HOST", "10.0.0.2") wpi.sim.enVar is not public. While groovy allows setting it, Kotlin does not. Until this is resolved, we work around as follows:
        environment["HALSIMWS_HOST"] = "10.0.0.2"
        addWebsocketsServer().apply {
            defaultEnabled = true
        }
        addWebsocketsClient().apply {
            defaultEnabled = true
        }
</#if>
<#if data.isXrpTemplate()>

        //Sets the XRP Client Host
        //envVar("HALSIMXRP_HOST", "192.168.42.1") wpi.sim.enVar is not public. While groovy allows setting it, Kotlin does not. Until this is resolved, we work around as follows:
        environment["HALSIMXRP_HOST"] = "192.168.42.1"
        addXRPClient().apply {
            defaultEnabled = true
        }
</#if>
    }
}
<#if data.isSystemCoreRobotTemplate()>

deployArtifact.configureApplication(application)
</#if>

// Set this to true to enable desktop support.
val includeDesktopSupport = [=data.getIncludeDesktopSupportGradleSetting()]

dependencies {
<#if data.getIncludeKotlinSupport()>
    kapt(wpi.java.deps.wpilibAnnotations())
<#else>
    annotationProcessor(wpi.java.deps.wpilibAnnotations())
</#if>
    implementation(wpi.java.deps.wpilib())
    implementation(wpi.java.vendor.java())
<#if data.isSystemCoreRobotTemplate()>

    systemcoreDebug(wpi.java.deps.wpilibJniDebug(NativePlatforms.systemcore))
    systemcoreDebug(wpi.java.vendor.jniDebug(NativePlatforms.systemcore))

    systemcoreRelease(wpi.java.deps.wpilibJniRelease(NativePlatforms.systemcore))
    systemcoreRelease(wpi.java.vendor.jniRelease(NativePlatforms.systemcore))
</#if>

    nativeDebug(wpi.java.deps.wpilibJniDebug(NativePlatforms.desktop))
    nativeDebug(wpi.java.vendor.jniDebug(NativePlatforms.desktop))
    simulationDebug(wpi.sim.enableDebug())

    nativeRelease(wpi.java.deps.wpilibJniRelease(NativePlatforms.desktop))
    nativeRelease(wpi.java.vendor.jniRelease(NativePlatforms.desktop))
    simulationRelease(wpi.sim.enableRelease())
<#if data.junitUseJUnitPlatform()>

    testImplementation(platform("org.junit:junit-bom:[=data.junit5Version]"))
    testImplementation("org.junit.jupiter:junit-jupiter-api")
    testImplementation("org.junit.jupiter:junit-jupiter-params")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
</#if>
}

java {
    sourceCompatibility = javaVersion
    targetCompatibility = javaVersion
}

<#if data.getIncludeKotlinSupport()>
kotlin {
    compilerOptions {
        jvmTarget = kotlinJvmTarget
    }

    // https://kotlinlang.org/docs/gradle-configure-project.html#gradle-java-toolchains-support
    jvmToolchain(javaLanguageVersion.asInt())
}

</#if>
tasks {
<#if data.junitUseJUnitPlatform()>

    test {
        useJUnitPlatform()
        systemProperty("junit.jupiter.extensions.autodetection.enabled", "true")
    }
</#if>
    compileJava {
        options.encoding = Charsets.UTF_8.name()
        // Configure string concat to always inline compile
        options.compilerArgs.add("-XDstringConcat=inline")
    }
<#if data.isSystemCoreRobotTemplate()>

    // Include a backup of the project's source, vendordeps, and build file in the deployed jar
    jar {
        from("src") { into("backup/src") }
        from("vendordeps") { into("backup/vendordeps") }
        from("build.gradle.kts") { into("backup") }
    }
</#if>
}

idea {
    project {
        // The project.sourceCompatibility setting is not always picked up, so we set explicitly
        languageLevel = IdeaLanguageLevel(javaVersion)
    }
    module {
        // Improve development & (especially) debugging experience (and IDEA's capabilities) by having libraries' source & javadoc attached
        isDownloadJavadoc = true
        isDownloadSources = true
        // Exclude the .vscode directory from indexing and search
        excludeDirs.add(file(".run" ))
        excludeDirs.add(file(".vscode" ))
    }
}

// Helper Functions to keep syntax cleaner
// @formatter:off
fun DependencyHandler.addDependencies(configurationName: String, dependencies: List<Provider<String>>) = dependencies.forEach { add(configurationName, it) }
fun DependencyHandler.systemcoreDebug(dependencies: List<Provider<String>>) = addDependencies("systemcoreDebug", dependencies)
fun DependencyHandler.systemcoreRelease(dependencies: List<Provider<String>>) = addDependencies("systemcoreRelease", dependencies)
fun DependencyHandler.nativeDebug(dependencies: List<Provider<String>>) = addDependencies("nativeDebug", dependencies)
fun DependencyHandler.simulationDebug(dependencies: List<Provider<String>>) = addDependencies("simulationDebug", dependencies)
fun DependencyHandler.nativeRelease(dependencies: List<Provider<String>>) = addDependencies("nativeRelease", dependencies)
fun DependencyHandler.simulationRelease(dependencies: List<Provider<String>>) = addDependencies("simulationRelease", dependencies)
fun DependencyHandler.implementation(dependencies: List<Provider<String>>) = dependencies.forEach{ implementation(it) }
fun DependencyHandler.annotationProcessor(dependencies: List<Provider<String>>) = dependencies.forEach{ annotationProcessor(it) }
<#if data.getIncludeKotlinSupport()>
fun DependencyHandler.kapt(dependencies: List<Provider<String>>) = dependencies.forEach{ add("kapt", it) }
</#if>
 // @formatter:on
