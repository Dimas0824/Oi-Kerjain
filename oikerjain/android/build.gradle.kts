import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    plugins.withId("com.android.library") {
        extensions.findByType(LibraryExtension::class.java)?.let { androidExtension ->
            if (androidExtension.compileSdk == 0) {
                androidExtension.compileSdk = 35
            }

            if (androidExtension.namespace.isNullOrBlank()) {
                val manifestFile = file("src/main/AndroidManifest.xml")
                val manifestPackage = manifestFile
                    .takeIf { it.exists() }
                    ?.readText()
                    ?.let { manifestText ->
                        Regex("package\\s*=\\s*\"([^\"]+)\"")
                            .find(manifestText)
                            ?.groupValues
                            ?.getOrNull(1)
                    }

                androidExtension.namespace = manifestPackage
                    ?: "com.generated.${project.name.replace('-', '_')}"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
