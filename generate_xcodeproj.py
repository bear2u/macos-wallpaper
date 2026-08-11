import os
import uuid

def gen_id():
    return uuid.uuid4().hex[:24].upper()

proj_id = gen_id()
target_id = gen_id()
build_cfg_list_proj = gen_id()
build_cfg_list_target = gen_id()
group_root = gen_id()
group_maclivewallpaper = gen_id()
group_app = gen_id()
group_models = gen_id()
group_views = gen_id()
group_wallpaper = gen_id()
group_services = gen_id()
group_resources = gen_id()
group_products = gen_id()

product_ref = gen_id()

sources_build_phase = gen_id()
resources_build_phase = gen_id()
frameworks_build_phase = gen_id()

cfg_debug_proj = gen_id()
cfg_release_proj = gen_id()
cfg_debug_target = gen_id()
cfg_release_target = gen_id()

files = [
    ("App/MacLiveWallpaperApp.swift", group_app),
    ("App/AppDelegate.swift", group_app),
    ("Models/Wallpaper.swift", group_models),
    ("Models/AppSettings.swift", group_models),
    ("Services/PreferenceStore.swift", group_services),
    ("Services/PowerStateObserver.swift", group_services),
    ("Services/ScreenManager.swift", group_services),
    ("Services/LoginItemManager.swift", group_services),
    ("Services/FileImportService.swift", group_services),
    ("Wallpaper/VideoPlaybackController.swift", group_wallpaper),
    ("Wallpaper/WallpaperWindowController.swift", group_wallpaper),
    ("Wallpaper/WallpaperManager.swift", group_wallpaper),
    ("Views/VideoPreviewView.swift", group_views),
    ("Views/EmptyStateView.swift", group_views),
    ("Views/SettingsView.swift", group_views),
    ("Views/MainView.swift", group_views),
    ("Views/MenuBarExtraView.swift", group_views),
]

resource_files = [
    ("Resources/Assets.xcassets", group_resources, "folder.assetcatalog"),
    ("Resources/Info.plist", group_resources, "text.plist.xml")
]

file_objects = []
build_file_objects = []
resource_build_file_objects = []

for filepath, g_id in files:
    f_id = gen_id()
    b_id = gen_id()
    filename = os.path.basename(filepath)
    file_objects.append((f_id, filename, filepath, g_id, "sourcecode.swift"))
    build_file_objects.append((b_id, f_id, filename))

for filepath, g_id, f_type in resource_files:
    f_id = gen_id()
    b_id = gen_id()
    filename = os.path.basename(filepath)
    file_objects.append((f_id, filename, filepath, g_id, f_type))
    if f_type == "folder.assetcatalog":
        resource_build_file_objects.append((b_id, f_id, filename))

pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
"""

for b_id, f_id, filename in build_file_objects:
    pbx += f"\t\t{b_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {f_id} /* {filename} */; }};\n"

for b_id, f_id, filename in resource_build_file_objects:
    pbx += f"\t\t{b_id} /* {filename} in Resources */ = {{isa = PBXBuildFile; fileRef = {f_id} /* {filename} */; }};\n"

pbx += f"""/* End PBXBuildFile section */

/* Begin PBXFileReference section */
\t\t{product_ref} /* MacLiveWallpaper.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = MacLiveWallpaper.app; sourceTree = BUILT_PRODUCTS_DIR; }};
"""

for f_id, filename, filepath, _, f_type in file_objects:
    pbx += f"\t\t{f_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = {f_type}; path = \"{filepath}\"; sourceTree = \"<group>\"; }};\n"

pbx += f"""/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{frameworks_build_phase} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{group_root} = {{
			isa = PBXGroup;
			children = (
\t\t\t\t{group_maclivewallpaper} /* MacLiveWallpaper */,
\t\t\t\t{group_products} /* Products */,
			);
			sourceTree = "<group>";
		}};
\t\t{group_products} = {{
			isa = PBXGroup;
			children = (
\t\t\t\t{product_ref} /* MacLiveWallpaper.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
\t\t{group_maclivewallpaper} = {{
			isa = PBXGroup;
			children = (
\t\t\t\t{group_app} /* App */,
\t\t\t\t{group_models} /* Models */,
\t\t\t\t{group_views} /* Views */,
\t\t\t\t{group_wallpaper} /* Wallpaper */,
\t\t\t\t{group_services} /* Services */,
\t\t\t\t{group_resources} /* Resources */,
\t\t\t);
			path = MacLiveWallpaper;
			sourceTree = "<group>";
		}};
\t\t{group_app} = {{
			isa = PBXGroup;
			children = (
"""

for f_id, filename, _, g_id, _ in file_objects:
    if g_id == group_app:
        pbx += f"\t\t\t\t{f_id} /* {filename} */,\n"
pbx += f"""\t\t\t);
			sourceTree = "<group>";
		}};
\t\t{group_models} = {{
			isa = PBXGroup;
			children = (
"""

for f_id, filename, _, g_id, _ in file_objects:
    if g_id == group_models:
        pbx += f"\t\t\t\t{f_id} /* {filename} */,\n"
pbx += f"""\t\t\t);
			sourceTree = "<group>";
		}};
\t\t{group_views} = {{
			isa = PBXGroup;
			children = (
"""

for f_id, filename, _, g_id, _ in file_objects:
    if g_id == group_views:
        pbx += f"\t\t\t\t{f_id} /* {filename} */,\n"
pbx += f"""\t\t\t);
			sourceTree = "<group>";
		}};
\t\t{group_wallpaper} = {{
			isa = PBXGroup;
			children = (
"""

for f_id, filename, _, g_id, _ in file_objects:
    if g_id == group_wallpaper:
        pbx += f"\t\t\t\t{f_id} /* {filename} */,\n"
pbx += f"""\t\t\t);
			sourceTree = "<group>";
		}};
\t\t{group_services} = {{
			isa = PBXGroup;
			children = (
"""

for f_id, filename, _, g_id, _ in file_objects:
    if g_id == group_services:
        pbx += f"\t\t\t\t{f_id} /* {filename} */,\n"
pbx += f"""\t\t\t);
			sourceTree = "<group>";
		}};
\t\t{group_resources} = {{
			isa = PBXGroup;
			children = (
"""

for f_id, filename, _, g_id, _ in file_objects:
    if g_id == group_resources:
        pbx += f"\t\t\t\t{f_id} /* {filename} */,\n"
pbx += f"""\t\t\t);
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{target_id} /* MacLiveWallpaper */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {build_cfg_list_target} /* Build configuration list for PBXNativeTarget "MacLiveWallpaper" */;
			buildPhases = (
\t\t\t\t{sources_build_phase} /* Sources */,
\t\t\t\t{frameworks_build_phase} /* Frameworks */,
\t\t\t\t{resources_build_phase} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = MacLiveWallpaper;
			productName = MacLiveWallpaper;
			productReference = {product_ref} /* MacLiveWallpaper.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{proj_id} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{target_id} = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = {build_cfg_list_proj} /* Build configuration list for PBXProject "MacLiveWallpaper" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {group_root};
			productRefGroup = {group_products} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
\t\t\t\t{target_id} /* MacLiveWallpaper */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{resources_build_phase} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
"""

for b_id, f_id, filename in resource_build_file_objects:
    pbx += f"\t\t\t\t{b_id} /* {filename} in Resources */,\n"

pbx += f"""\t\t\t);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{sources_build_phase} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
"""

for b_id, f_id, filename in build_file_objects:
    pbx += f"\t\t\t\t{b_id} /* {filename} in Sources */,\n"

pbx += f"""\t\t\t);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{cfg_debug_proj} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.0;
			}};
			name = Debug;
		}};
\t\t{cfg_release_proj} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_FAST_MATH = YES;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				SWIFT_VERSION = 5.0;
			}};
			name = Release;
		}};
\t\t{cfg_debug_target} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_IDENTITY = "-";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "MacLiveWallpaper/Resources/Info.plist";
				PRODUCT_BUNDLE_IDENTIFIER = com.symverse.MacLiveWallpaper;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
			}};
			name = Debug;
		}};
\t\t{cfg_release_target} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_IDENTITY = "-";
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "MacLiveWallpaper/Resources/Info.plist";
				PRODUCT_BUNDLE_IDENTIFIER = com.symverse.MacLiveWallpaper;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{build_cfg_list_proj} /* Build configuration list for PBXProject "MacLiveWallpaper" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
\t\t\t\t{cfg_debug_proj} /* Debug */,
\t\t\t\t{cfg_release_proj} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
\t\t{build_cfg_list_target} /* Build configuration list for PBXNativeTarget "MacLiveWallpaper" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
\t\t\t\t{cfg_debug_target} /* Debug */,
\t\t\t\t{cfg_release_target} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {proj_id} /* Project object */;
}}
"""

os.makedirs("MacLiveWallpaper.xcodeproj", exist_ok=True)
with open("MacLiveWallpaper.xcodeproj/project.pbxproj", "w") as f:
    f.write(pbx)

print("Cleaned up resource paths in generate_xcodeproj.py")
