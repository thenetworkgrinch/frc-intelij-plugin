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
import edu.wpi.first.deployutils.deploy.artifact.FileTreeArtifact
import edu.wpi.first.gradlerio.GradleRIOPlugin
import edu.wpi.first.gradlerio.deploy.roborio.FRCJavaArtifact
import edu.wpi.first.gradlerio.deploy.roborio.RoboRIO
import edu.wpi.first.toolchain.NativePlatforms
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
<#if data.getIncludeKotlinSupport()>
    kotlin("jvm") version "[=data.kotlinVersion]"
</#if>
    id("edu.wpi.first.GradleRIO") version "[=data.wpilibVersion.versionString]"
    idea
}


val javaVersion: JavaVersion by extra { JavaVersion.VERSION_17 }
val javaLanguageVersion: JavaLanguageVersion by extra { JavaLanguageVersion.of(javaVersion.toString()) }
val jvmVendor: JvmVendorSpec by extra { JvmVendorSpec.ADOPTIUM }
<#if data.getIncludeKotlinSupport()>
val kotlinJvmTarget: JvmTarget = JvmTarget.fromTarget(javaVersion.toString())
</#if>

@Suppress("PropertyName")
val ROBOT_MAIN_CLASS = "[=data.mainClassFQ]"

<#if data.isRoboRioRobotTemplate()>
// Define my targets (RoboRIO) and artifacts (deployable files)
// This is added by GradleRIO's backing project DeployUtils.
deploy {
    targets {
        val roborio by register<RoboRIO>("roborio") {
            // Team number is loaded either from the .wpilib/wpilib_preferences.json
            // or from command line. If not found an exception will be thrown.
            // You can use project.frc.getTeamOrDefault(####) instead of project.frc.teamNumber
            // if you want to store a team number in this file.
            team = frc.teamNumber
            debug = frc.getDebugOrDefault(false)
        }

        roborio.artifacts {
            register<FRCJavaArtifact>("frcJava") {
                setJarTask(tasks.jar)
            }

            register<FileTreeArtifact>("frcStaticFileDeploy") {
                files = project.fileTree("src/main/deploy")
                directory = "/home/lvuser/deploy"
                // Change to true to delete files on roboRIO that no longer exist in deploy directory of this project
                deleteOldFiles = false
            }
        }
    }
}
</#if>

wpi {
    with(java) {
<#if data.isRoboRioRobotTemplate()>
        // Set to true to use debug for all targets including JNI, which will drastically impact
        // performance.
        debugJni = false
</#if>
        configureExecutableTasks(tasks.jar.get())
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

// Set this to true to enable desktop support.
val includeDesktopSupport = [=data.getIncludeDesktopSupportGradleSetting()]

dependencies {
    annotationProcessor(wpi.java.deps.wpilibAnnotations())
    implementation(wpi.java.deps.wpilib())
    implementation(wpi.java.vendor.java())
<#if data.isRoboRioRobotTemplate()>

    roborioDebug(wpi.java.deps.wpilibJniDebug(NativePlatforms.roborio))
    roborioDebug(wpi.java.vendor.jniDebug(NativePlatforms.roborio))

    roborioRelease(wpi.java.deps.wpilibJniRelease(NativePlatforms.roborio))
    roborioRelease(wpi.java.vendor.jniRelease(NativePlatforms.roborio))
</#if>

    nativeDebug(wpi.java.deps.wpilibJniDebug(NativePlatforms.desktop))
    nativeDebug(wpi.java.vendor.jniDebug(NativePlatforms.desktop))
    simulationDebug(wpi.sim.enableDebug())

    nativeRelease(wpi.java.deps.wpilibJniRelease(NativePlatforms.desktop))
    nativeRelease(wpi.java.vendor.jniRelease(NativePlatforms.desktop))
    simulationRelease(wpi.sim.enableRelease())
<#if data.junitUseJUnitPlatform()>

    testImplementation(platform("org.junit:junit-bom:5.11.4"))
    testImplementation("org.junit.jupiter:junit-jupiter-api")
    testImplementation("org.junit.jupiter:junit-jupiter-params")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine")
</#if>
}

java {
    toolchain {
        languageVersion = javaLanguageVersion
        vendor = jvmVendor
    }
}

<#if data.getIncludeKotlinSupport()>
    
kotlin {
    compilerOptions {
        jvmTarget = kotlinJvmTarget
    }

    jvmToolchain {
        // https://kotlinlang.org/docs/gradle-configure-project.html#gradle-java-toolchains-support
        languageVersion = javaLanguageVersion
        vendor = jvmVendor
    }
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

    // Setting up my Jar File. In this case, adding all libraries into the main jar ('fat jar')
    // in order to make them all available at runtime. Also adding the manifest so WPILib
    // knows where to look for our Robot Class.
    jar {
        group = "build"
        manifest(GradleRIOPlugin.javaManifest(ROBOT_MAIN_CLASS))
        duplicatesStrategy = DuplicatesStrategy.INCLUDE

        // Adding this closure makes this expression lazy, allowing GradleRIO to add
        // its dependencies before the jar task is fully configured.
        from({ configurations.runtimeClasspath.get().map { if (it.isDirectory) it else zipTree(it) } })
        
        <#if data.isRoboRioRobotTemplate()>
        // Include a backup of the project's source, vendordeps, and build file in the deployed jar
        from("src") { into("backup/src") }
        from("vendordeps") { into("backup/vendordeps") }
        from("build.gradle.kts") { into("backup") }
        </#if>
    }
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
fun DependencyHandler.roborioDebug(dependencies: List<Provider<String>>) = addDependencies("roborioDebug", dependencies)
fun DependencyHandler.roborioRelease(dependencies: List<Provider<String>>) = addDependencies("roborioRelease", dependencies)
fun DependencyHandler.nativeDebug(dependencies: List<Provider<String>>) = addDependencies("nativeDebug", dependencies)
fun DependencyHandler.simulationDebug(dependencies: List<Provider<String>>) = addDependencies("simulationDebug", dependencies)
fun DependencyHandler.nativeRelease(dependencies: List<Provider<String>>) = addDependencies("nativeRelease", dependencies)
fun DependencyHandler.simulationRelease(dependencies: List<Provider<String>>) = addDependencies("simulationRelease", dependencies)
fun DependencyHandler.implementation(dependencies: List<Provider<String>>) = dependencies.forEach{ implementation(it) }
fun DependencyHandler.annotationProcessor(dependencies: List<Provider<String>>) = dependencies.forEach{ annotationProcessor(it) }
 // @formatter:on