# WDAC, Applocker and Autopilot. 
How to add WDAC to an Applocker secured environment.

Working on a Modern Workplace implementation at one of my clients, I was asked to implement WDAC as part of the zero trust workplace setup. The workplace is Windows 11, deployed via OSDcloud and Autopilot, Azure AD Joined only, with some 150 Win32 applications.

Till then application control was implemented via Applocker. Due to time constraints we decided to see if we could implement the WDAC Managed Installer alongside Applocker. The Managed Installer should tag all apps deployed via the Intune Management Extension during Autopilot rollout as 'trusted'. New Intune apps would not need new Applocker rules to run. Existing Applocker rules could be migrated to WDAC rules later without interfering with the rollout deadline.

However, WDAC is poorly adapted and documented, so we ran into many challenges.

# Managed Installer
The Managed Installer can be enabled in Intune only tenant wide. We were still on Windows 10 (deployed via SCCM) and only wanted to test and implement the Managed Installer on the new Windows 11 workspace, which was still in test phase.

So we used the Microsoft recommended way to enable the Managed Installer only on designated devices with this (GitHub - vincentverstraeten/ManagedInstaller: Managed Installer Proactive Remediation script from Microsoft) script during device ESP (as a Win32 application scripted with PSADT). The script basically merges 3 Applocker rulecollections with the existing Applocker rules as described here: Allow apps deployed with a WDAC managed installer - Windows Security | Microsoft Learn.

The script seemed to work because we could see files tagged by ManagedInstaller afterwards on existing machines as described here: Managed installer and ISG technical reference and troubleshooting guide - Windows Security | Microsoft Learn. However, when running the script during ESP for new devices all went wrong.

## Problem 1:
ESP was broken, after device ESP either account ESP would not run or ran forever ‘identifying …’, timing out finally.
## Solution 1:
The script is merging the Managed Installer into the Applocker rulecollections but needs a reboot afterwards. This pending reboot breaks ESP. So we decided to run the script in the OSDcloud phase as a solution.

## Problem 2:
Applocker Intune device configuration ran into problems and the configuration policies all got an error.

# Applocker CSP
The Applocker CSP (./Vendor/MSFT/AppLocker/ApplicationLaunchRestrictions/apps/<group>/Policy) was used in a custom OMA-URI to deploy Applocker rules on Windows 10 and Windows 11. Exe, Msi and Script groups were set to ‘Enabled’, Appx was set to ‘AuditOnly’.

So I decided to use ‘Get-Applockerpolicy’ to see what was going on. Surprise, surprise: no Applocker configuration could be found but the ‘AuditOnly’ configuration from the MS script! So Applocker was effectively turned off.

Turned out that adding Appplocker policies via CSP with a different Enforcement mode from the ‘AuditOnly’ mode set in the script did not get effectuated and errored out.

![image](https://github.com/Frank-GTH/WDAC-Applocker/assets/119516706/1f2b7cdb-ec79-4f5d-97d5-6395a69077c5)

## Solution 2:
So I decided to use ‘Set-ApplockerPolicy’ to import the rules (Exe, Msi, Appx and Script) via xml files in ‘AuditOnly’ mode and merge them with the rules from the MS script. After the merge of the rules I used ‘Set-ApplockerPolicy’ again to export the rules, change ‘AuditOnly’ to ‘Enabled’ and import the rules (no merge). Since this would cause a reboot during ESP I used a script to wait for the end of ESP (user desktop ready) and then do the changes with an immediate reboot.

The script can be found here: …..

Results after the script and after ESP:

![image](https://github.com/Frank-GTH/WDAC-Applocker/assets/119516706/307afd85-40f2-4136-a61d-bea2e4d389a6)

And Appplocker policy via CSP with corresponding Enforcement settings will apply nicely again.

# WDAC policies
Creating WDAC policies is fairly well documented, so I did not have any problems there. I created a basic policy in audit mode to enable the Managed Installer and trust the Patch My PC certificate, along with some basic protection:

![image](https://github.com/Frank-GTH/WDAC-Applocker/assets/119516706/6ed28c0a-61f3-400a-a494-c2f240cd4a4c)

However, implementing the policy was a challenge again.

## Problem 3:
Implementing the WDAC device based policy caused account ESP to break again, ‘identifying …’ forever and time out.
## Solution 3:
After a lot of testing I discovered that applying the WDAC policy to the device after ESP was working like a charm. So I created a dynamic group based on the device name starting with ‘MW1-‘. During ESP the devices were named ‘MW-‘. I added the rename action to the script at the end of the ESP and policies were applied successfully.

Results after implementing WDAC policies and enabling event ID 3090 in the CodeIntegrity log:

![image](https://github.com/Frank-GTH/WDAC-Applocker/assets/119516706/4294fe04-b075-42ab-b490-6215c9eda7dc)
![image](https://github.com/Frank-GTH/WDAC-Applocker/assets/119516706/7ba95b57-67cc-404f-8817-f4f685bad2ea)
![image](https://github.com/Frank-GTH/WDAC-Applocker/assets/119516706/ef0b8c07-fe8e-4e02-aebe-f4b12b22d406)

At that point in time we were getting close to project deadline and ran out of test time. Since WDAC and Applocker can be very intrusive we decided not to implement at this stage. I just wanted to share my journey so other admins can benefit.
