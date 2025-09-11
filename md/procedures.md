# procedures.md

IT procedures.

```
# New user, Нов Служител, Онбординг:

## keywords: active directory; add ad group; ad; new accound; нов акаунт; онбординг; добавяне на нов служител

### **Steps:**

1. Open the "IDM".
2. See if ID is available
3. Check for matching name in AD 
	- If you find a match change the existing one by adding their job title to the name 
	- !!! If not changed, the new account will overwrite the old.
4. Approve in IDM.
5. In AD change SAM name to the ID and set email to 'dsk.grp'
6. Get model ID to get the AD groups and give them to the new user.
7. Add the groups to the new user.
8. Approve it in IDM
9. If the user is in Central Unit (0099)
	- Create Dimension account from IDM or DIM using model ID
	- Set passowrd for DIM
10. If the user is in Regions
	- Do NOT create DIM
11. Add the user to the DB for the correct location
12. Send email in Remedy:
	- User ID : 
	- User name: 
```

```
# Reset User Password:

## keywords: reset password; user account

### **Steps:**

1. Open Active Directory Users and Computers (ADUC).
2. Search for the user.
3. Right-click the user account and select "Reset Password...".
4. Enter a new password and confirm.
5. Uncheck "User must change password at next logon"
```

```
# Archimed - Access to SWIFT Transactions:

## keywords: archimed; swift transactions; access to swift

### **Steps:**

1. In Add AD group, assign APG Archimed.
2. In BankWay for JD, add DK5555
```

```
# MFA Account Password Error Login:

## keywords: mfa; account; password; error; login

### **Steps:**

1. Verify the user account experiencing the MFA login error.
2. Reset MFA settings as required.
3. Test login to ensure the password and MFA work correctly.
```

```
# Permissions Denied / Email Access:

## keywords: mail; permission; access denied; email

### **Steps:**

1. Check the user's email permissions.
2. Add user to APG Mail group in Active Directory if necessary.
3. Verify the user can access email and Teams.
```

```
# CRM Access:

## keywords: crm; groups; crm access

### **Steps:**

1. Verify user needs CRM access.
2. Add user to APG CRM Admin group in Active Directory.
```

```
# Каса с кик / Главна каса / Замeстване на мениджър:

## keywords: каса; главна; киб; заместване

### **Steps:**

1. Change JD to PBRYNK6.
2. In BankWay:
   - AL to 50
   - AC to 9
   - Confirmation to Yes
```

```
# Сбо Remote Overwrite with Swift Бисера:

## keywords: сбo; remote; overwrite; swift; бисера

### **Steps:**

1. Change JD to BRIBRK6
```

```
# Access to CLAVIS:

## keywords: clavis; оператор; swift; access to clavis

### **Steps:**

1. Add user to APG CLAVIS Admin group in Active Directory
```

```
# Vpn Access Required:

## keywords: vpn; access; required

### **Steps:**

1. Advise the user to restart their VPN client.
2. Check the network connection.
```

```
# SSL Error / Certificate Required:

## keywords: ssl; certificate; error

### **Steps:**

1. Advise the user to clear their browser cache.
2. Retry the application.
3. Ensure the correct SSL certificate is installed if needed.
```

```
# Wireless / Wifi Access:

## keywords: wireless; wifi; office; access

### **Steps:**

1. Add user to APG Wireless Admin group in Active Directory.
2. Confirm wireless access on office devices.
```

```
# Account Locked:

## keywords: account locked; user account; disabled

### **Steps:**

1. Check if the account is locked in Active Directory or relevant system.
2. Unlock the account as needed.
```

```
# Password:

## keywords: password reset; login; reset password; нова парола, парола за dimension; парола за bankway

### **Steps:**

1. Advise user to reset their password in Active Directory.
2. Ensure the user can login after the reset.
```

```
# Permission Denied / Access Denied:

## keywords: permission denied; access denied; rights; required access

### **Steps:**

1. Verify the required system access.
2. Grant necessary permissions to the user.
3. Confirm user can access the requested system.
```

```
# General Error:

## keywords: general error; application error

### **Steps:**

1. Advise user to restart the application.
```
