# WDAC, Applocker and Autopilot. 
Add WDAC to Applocker secured environment

Working on a Modern Workplace implementation at one of my clients I was asked to implement WDAC as part of the zero trust workplace setup. The workplace is Windows 11, deployed via OSDcloud and Autopilot, Azure AD Joined only with some 150 Win32 applications.

Till then application control was implemented via Applocker. Due to time constraints we decided to see if we could implement the WDAC Managed Installer alongside Applocker. The Managed Installer should tag all apps deployed via the Intune Management Extension during Autopilot rollout as 'trusted'. New Intune apps would not need new Applocker rules to run. Existing Applocker rules could be migrated to WDAC rules later without interfering with the rollout deadline.
However, WDAC is poorly adapted and documented, so we ran into many challenges.

Managed Installer
The Managed Installer can be enabled in Intune only tenant wide. We were still on Windows 10 (deployed via SCCM) and only wanted to test and implement the Managed Installer on the new Windows 11 workspace which was still in test phase.
