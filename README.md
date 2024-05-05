# WDAC, Applocker and Autopilot. 
How to add WDAC to an Applocker secured environment.

Working on a Modern Workplace implementation at one of my clients I was asked to implement WDAC as part of the zero trust workplace setup. The workplace is Windows 11, deployed via OSDcloud and Autopilot, Azure AD Joined only with some 150 Win32 applications.

Till then application control was implemented via Applocker. Due to time constraints we decided to see if we could implement the WDAC Managed Installer alongside Applocker. The Managed Installer should tag all apps deployed via the Intune Management Extension during Autopilot rollout as 'trusted'. New Intune apps would not need new Applocker rules to run. Existing Applocker rules could be migrated to WDAC rules later without interfering with the rollout deadline.

However, WDAC is poorly adapted and documented, so we ran into many challenges.

# Managed Installer
The Managed Installer can be enabled in Intune only tenant wide. We were still on Windows 10 (deployed via SCCM) and only wanted to test and implement the Managed Installer on the new Windows 11 workspace which was still in test phase.

So we used the Microsoft recommended way to enable the Managed Installer only on designated devices with this (GitHub - vincentverstraeten/ManagedInstaller: Managed Installer Proactive Remediation script from Microsoft) script during device ESP (as a Win32 application scripted with PSADT). The script basically merges 3 Applocker rulecollections with the existing Applocker rules as described here: Allow apps deployed with a WDAC managed installer - Windows Security | Microsoft Learn.

The script seemed to work because we could see files tagged by ManagedInstaller afterwards on existing machines as described here: Managed installer and ISG technical reference and troubleshooting guide - Windows Security | Microsoft Learn. However, when running the script during ESP for new devices all went wrong.

## Problem 1:
ESP was broken, after device ESP either account ESP would not run or ran forever ‘identifying …’, timing out finally.
## Solution 1:
The script is merging the Managed Installer into the Applocker rulecollections but needs a reboot afterwards. This pending reboot breaks ESP. So we decided to run the script in the OSDcloud phase as a solution.
