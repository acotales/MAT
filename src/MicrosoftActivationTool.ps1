#Requires -Version 5.1

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Drawing

# ── XAML Definitions ──────────────────────────────────────────────────────────
[xml]$XAML = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Microsoft Activation Tool"
    Height="420"
    Width="560"
    WindowStartupLocation="CenterScreen"
    ResizeMode="CanMinimize"
    Background="#0F1117">

    <Window.Resources>

        <!-- ── Colour Palette ── -->
        <Color x:Key="AccentColor">#6C63FF</Color>
        <Color x:Key="AccentHover">#8B85FF</Color>
        <Color x:Key="AccentPressed">#4E47D6</Color>
        <Color x:Key="SurfaceColor">#1A1D27</Color>
        <Color x:Key="BorderColor">#2A2D3E</Color>

        <SolidColorBrush x:Key="AccentBrush"   Color="{StaticResource AccentColor}"/>
        <SolidColorBrush x:Key="SurfaceBrush"  Color="{StaticResource SurfaceColor}"/>
        <SolidColorBrush x:Key="BorderBrush"   Color="{StaticResource BorderColor}"/>

        <!-- ── Button Style ── -->
        <Style x:Key="ModernButton" TargetType="Button">
            <Setter Property="Background"      Value="{StaticResource AccentBrush}"/>
            <Setter Property="Foreground"      Value="White"/>
            <Setter Property="FontFamily"      Value="Segoe UI Semibold"/>
            <Setter Property="FontSize"        Value="14"/>
            <Setter Property="Width"           Value="200"/>
            <Setter Property="Height"          Value="40"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor"          Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Root"
                                Width="{TemplateBinding Width}"
                                Height="{TemplateBinding Height}"
                                Background="{TemplateBinding Background}"
                                CornerRadius="8"
                                SnapsToDevicePixels="True">
                            <Border.Effect>
                                <DropShadowEffect Color="#6C63FF" BlurRadius="18"
                                                  ShadowDepth="0" Opacity="0.5"/>
                            </Border.Effect>
                            <ContentPresenter HorizontalAlignment="Center"
                                              VerticalAlignment="Center"
                                              Margin="0,0,0,0"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Root" Property="Background">
                                    <Setter.Value>
                                        <SolidColorBrush Color="{StaticResource AccentHover}"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Root" Property="Background">
                                    <Setter.Value>
                                        <SolidColorBrush Color="{StaticResource AccentPressed}"/>
                                    </Setter.Value>
                                </Setter>
                                <Setter TargetName="Root" Property="Opacity" Value="0.85"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Root" Property="Opacity" Value="0.4"/>
                                <Setter TargetName="Root" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="#6C63FF" BlurRadius="0"
                                                          ShadowDepth="0" Opacity="0"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ── ProgressBar Style (true indeterminate sliding animation) ── -->
        <Style x:Key="GlowProgressBar" TargetType="ProgressBar">
            <Setter Property="Height"          Value="8"/>
            <Setter Property="IsIndeterminate" Value="True"/>
            <Setter Property="Background"      Value="#2A2D3E"/>
            <Setter Property="Foreground"      Value="{StaticResource AccentBrush}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ProgressBar">
                        <!-- Track -->
                        <Border x:Name="PART_Track"
                                CornerRadius="4"
                                Background="{TemplateBinding Background}"
                                ClipToBounds="True">
                            <!-- Sliding glowing pill -->
                            <Canvas x:Name="PART_GlowRect" ClipToBounds="False">
                                <Border x:Name="GlowPill"
                                        Canvas.Left="-110"
                                        Width="110"
                                        Height="8"
                                        CornerRadius="4"
                                        ClipToBounds="False">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                            <GradientStop Color="Transparent"    Offset="0.0"/>
                                            <GradientStop Color="#6C63FF"        Offset="0.4"/>
                                            <GradientStop Color="#A78BFA"        Offset="0.6"/>
                                            <GradientStop Color="Transparent"    Offset="1.0"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                    <Border.Effect>
                                        <DropShadowEffect Color="#6C63FF" BlurRadius="12"
                                                          ShadowDepth="0" Opacity="0.85"/>
                                    </Border.Effect>
                                </Border>
                            </Canvas>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsIndeterminate" Value="True">
                                <Trigger.EnterActions>
                                    <BeginStoryboard>
                                        <Storyboard RepeatBehavior="Forever">
                                            <DoubleAnimation
                                                Storyboard.TargetName="GlowPill"
                                                Storyboard.TargetProperty="(Canvas.Left)"
                                                From="-110" To="330"
                                                Duration="0:0:1.6"
                                                RepeatBehavior="Forever"
                                                AutoReverse="False"/>
                                        </Storyboard>
                                    </BeginStoryboard>
                                </Trigger.EnterActions>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

    </Window.Resources>

    <!-- ── Root Grid ── -->
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>   <!-- 0 · Decorative top-bar -->
            <RowDefinition Height="*"/>      <!-- 1 · Main content -->
            <RowDefinition Height="Auto"/>   <!-- 2 · Footer -->
        </Grid.RowDefinitions>

        <!-- Decorative top accent bar -->
        <Rectangle Grid.Row="0" Height="5">
            <Rectangle.Fill>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                    <GradientStop Color="#6C63FF" Offset="0"/>
                    <GradientStop Color="#A78BFA" Offset="0.5"/>
                    <GradientStop Color="#6C63FF" Offset="1"/>
                </LinearGradientBrush>
            </Rectangle.Fill>
        </Rectangle>

        <!-- ── Main Content Card ── -->
        <Border Grid.Row="1"
                Margin="34,32,34,12"
                Background="{StaticResource SurfaceBrush}"
                BorderBrush="{StaticResource BorderBrush}"
                BorderThickness="1"
                CornerRadius="16">
            <Border.Effect>
                <DropShadowEffect Color="Black" BlurRadius="30"
                                  ShadowDepth="4" Opacity="0.45"/>
            </Border.Effect>

            <StackPanel VerticalAlignment="Center"
                        HorizontalAlignment="Center"
                        Margin="40,36">

                <!-- Title -->
                <TextBlock x:Name="TitleLabel"
                        Text="Microsoft Activation Tool"
                        FontFamily="Segoe UI Light"
                        FontSize="20"
                        FontWeight="Light"
                        Foreground="White"
                        HorizontalAlignment="Center"
                        Margin="0,0,0,10"/>

                <!-- Subtitle -->
                <TextBlock x:Name="Subtitle"
                        Text="Version 1.0.0"
                        FontFamily="Segoe UI"
                        FontSize="11"
                        Foreground="#7B7F9E"
                        HorizontalAlignment="Center"
                        TextAlignment="Center"
                        Margin="0,0,0,20"/>

                <!-- First button -->
                <Button x:Name="Button1"
                        Content="Activate Windows"
                        Style="{StaticResource ModernButton}"
                        Margin="0,0,0,12"/>

                <!-- Second button -->
                <Button x:Name="Button2"
                        Content="Activate MS Office"
                        Style="{StaticResource ModernButton}"
                        Margin="0,0,0,20"/>

                <!-- Status label -->
                <TextBlock x:Name="StatusLabel"
                        Text="Status: Ready"
                        FontFamily="Segoe UI"
                        FontSize="12"
                        Foreground="#7B7F9E"
                        HorizontalAlignment="Center"
                        Margin="0,0,0,18"/>

                <!-- Progress bar -->
                <ProgressBar x:Name="ProgressBar"
                            Style="{StaticResource GlowProgressBar}"
                            Width="320"
                            Visibility="Collapsed"
                            Margin="0,0,0,0"/>

            </StackPanel>
        </Border>

        <!-- ── Footer ── -->
        <TextBlock Grid.Row="2"
                   Text="&#x00A9; 2026 Anthony Cotales. All rights reserved."
                   FontFamily="Segoe UI"
                   FontSize="11"
                   Foreground="#3D4060"
                   HorizontalAlignment="Center"
                   Margin="0,0,0,12"/>
    </Grid>
</Window>
"@

# ── Embedded variable (Window Icon) ───────────────────────────────────────────
$icoBase64 = @"
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
AAAAAAAAAAAAAAAAAO/v7xLd3uC3xcjI/+Xm6JcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAA9fb3CuLj5a2+t7j/fnt9/7Gxs//19vZ2AAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD6+/sO3N3etZ+Zmf+vnZ//g3p6/19jZ/+4t7XL7+/v
IAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD39vehwbe3/4V5dv+ql5b/i4B9
/3tzcf+Mion/6erqywAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADr6erDqJmY
/4J2c/+hkZD/i317/4l7ef+Dfnz/4eLi6wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAADp5+fDpZWT/39zb/+jk5H/m4qH/311cP+Ujov/5OXkwwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAADj4OHDnZCO/3twa/+7qqf/oI6M/5SJhf/Qzs3/8vLySAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP7+/iDX1NXVo5ST/3VqZv++rKr/p5WS/5eNi//d3t2n+/v9
AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP7//2ba1df/t6Wl/3luav/BsK//qpeV
/3Vxbf+srqzh7u7uNgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP7+/jzi3+Dnwa6v
/4J4df/GtrX/sJyb/66fnf+XlZP/5ufn6wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
/zSq5/9E2f7/LLTx/xyb7/8zufn/i8rr8ejx91j0+fsCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8vLyDurr7M/MzM7/6Nna
/+/X2f/y2dz/6NHW/+HLzf/fxcb/zLq8/3J0d/+apq7/sb/J/7fF0P/Ez9D/093fse7y863f7/Gtkt7y
60LA9P8UgNX/Kpvd/0XP/P81tvX/HqDs/zq1+P+Lyuv72ur0ZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADa2Nsg3tvd
z9/a2//49fb/8N3f//Lc3//r1dv/5s/U/9rGyv+noav/bIuo/zRyo/85gLn/Q5DJ/0aVyv9Cjb3/W4up
/26Sqf92zuP/T9z7/xaH1/8kmNv/TN78/zO28v8ene3/NLv4/4nJ6ffv9flWAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
ANza2hLX0tHP4tTW//Xq6//15uj/893g//Hb3//r1Nn/0sXL/5Wqvf9wr9f/WrLu/zuu9/9Ds/z/T8L8
/1fQ/f9f2Pz/a9jy/2rV6/9Z5vz/SuL+/z7E8f9D1fn/L7ry/xic7/8stfr/i8np9dPm72YAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAA8/T0HtrZ2MvVx8f/7Nna/+na2//p2tz/7Nja/+3W2P/Px83/lrzM/37b8v9kzf7/Ur39
/zzF/v9G0v7/VOb//1fr//9n7v//Zu///1zw//9W7f//Uer//1Tn//9B1/r/DY3k/yuv8P+FyOr/7/X5
VAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAA7u7ux8vEwv/cysr/487Q/+TQ0v/j09b/49HU/9DIzf+Zvc7/huL3
/2bU/f8yqPv/KKX8/yi3/v84x/7/R+D//03s//9T8v//XfP//1X0//9U8///T+///1Lp//9J5P7/NMP0
/0STwf+hwtF2AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8/P1K4dra8dHDw//UwL//1cHC/9jGx//gycr/3MrN
/6TBzf+X5vb/Z9D7/zCT5v84qfX/P7z9/0fH/v88yP7/PNv//0rk//9P7f//UPL//1P0//9O8f//TO7/
/0/n//9L4///SN7+/3O72/+vxM5cAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD19fWF49XX/97Jy//CrKv/wrKy
/8q8vv/SwsP/vrzB/6jb6P+N6Pz/MYfY/ylWiv+Fqrv/ru72/7P5//+Z7f7/Stf+/0Xg//9L6P//TO//
/07v//9K7v//SOv//0nm//9F4v//TN38/5LN4P/i6uxcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADu7u2F6t/g
/865uf+1oKL/w7e6/+vn6P/t6ur/wd7n/67y+v9kufD/JGKg/4uWo//g4+X/xuLp/8T4+//U/f//pPD/
/07b//9F4v//R+v//0zp//9K6f//Seb+/0bd/v9D3v3/RqvR/5Ssuf/w8/RcAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAADx7u6F8Ofm/7Slo/+8rq3/8u/w//z9/f/2+/z/vezz/6js+v83gtb/WW6H/97h4//7/f3/9/n6
/8nf5P/O8/X/4v7//6ny//9T3/7/ReP+/0nm//9B4P//Pd7//0PX//86ue7/IW2//3SUrv/p7/FcAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAD37+6F7+fl/6eZmf+qoqT/5ejp8evv7+vk6+3tuev1/6Df9P8gabj/b3h8
/9Ta1//m6+/37e7u69jd3OvG3+Ltyvb3/8n9/v+q8/7/S9v+/z7a//8/3f//O9r+/zrW//8/uPb/H3zh
/16IrP/U2ttcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD69vmF9fPw/6mgoP+blpb/7e3tVvn6+nDR3eCByOrx
/5rZ9P8aYKv/YWVj/6eqpf/h5N/L9vb3ZgAAAADS3N4WxOHnyb71+f/Z/v//qO78/1vf//9K5f//UOP+
/07i//9O0/3/HYb3/09+tP/FyclcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD49viF/Pn1/8S5uP+Gg4P/xMbG
36qrq/99gYP/wdPa/6be9v8iY6f/MTEs/01KQv98fnv/1NfW+/f4+IX6+/sI3N/hhZ+0u//E8vT/x/3+
/57x//9R5f//UeT+/1Pn/v9T3f7/HpH7/1iHvP/a4ONcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD3+PmF/f38
/97Z2f9taWv/X2Bd/2NhXf9HRT//qbW5/8Du/f8qgcT/S1BQ/4KBff9iY2H/l56b/+nq6P/3+PhIxr+/
xZ+Vlf+nvcb/sO/3/6L1//9t5/7/TNn+/0bd/v9N0f7/Hp/6/2uZwv/m6e1cAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAD6+/sQ+fj55fn5+v+dk5L/WFJN/1BKRP+Wk4//zOHm/97z/f9KpeX/SWmH/8vSy//Kysr/mJqb
/7a6uf/Y1tbrlZCP/8vAvf+1qqv/fKm9/4Xm+/9z4v3/RtH+/0DX/v88w/3/I5rv/5G0zu37/PxGAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAD7+/xQ4ODh8/j5+f/Y1tb/fXdz/3V1bv/Z3tzt4PD4r+f5/P+Ozfv/J2mm
/4OTnv/LzMz/oaSk/4+Pj/+SiYj/pqOl/9DMyP+inJn/zdfd/7Xh8/9e2fn/N8b+/0XK/v8rqvz/Ko3X
/9Hi67cAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD29/eF1tbW/+Hg4v/7/Pz/1dbX/4mGg/90d3r9rLKy
+a/i6//H9vv/SpLX/ypUg/+Khob/hY+J/3Braf+jnpn/3NXV/7Wtqv+9v7zP7O3tEPX7/XyL0e//Mbf5
/z60/P8ljvX/grPe/9Ph5xoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADr6uaF2drX/7Oysv/39/j5/f7+
/+bk5P+1s7D/jYaD/3mRof+RzOn/eq7X/0BslP+Kh4X/dW5p/4yOi//LxMH/tKiq/7i1uf/r7Oxs9fn8
p7na7bFdr+v/Pq/4/y2R+f9HkOP9xdfomfz8/QYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC0sK+FkIuF
/8nJxf/4+fk6+vv73/Xz9P/r5OT/1cbJ/72wtv+TrcT/gbPP/5qnpv+PjIj/YGx8/zZbhf9EYIL/bYOa
/6XA1f+jweH/aKTd/0OZ3f9Qr/f/N5/3/02c5P/D2+jNAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAACflpOFioF8/+De3Yv+//8C+vv8me/u7uHg2dzl1c/Q/+bi4v/Z2t3/n6Gk/5GRjP97f4D/fafH
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
"@

# ── Application update batch script ───────────────────────────────────────────
$batchContent = @"
@echo off
:wait
timeout /t 1 /nobreak >nul
tasklist /FI "PID eq $PID" 2>nul | find "$PID" >nul
if not errorlevel 1 goto wait
copy /Y "{0}" "{1}" >nul
start powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "{1}"
del /F /Q "%~f0" >nul 2>&1
del /F /Q "{0}" >nul 2>&1
"@

# ── App configuration ─────────────────────────────────────────────────────────
$App = @{
    Name          = "Microsoft Activation Tool"
    Version       = "1.0.0"
    Repo          = @{
        Name       = "MAT"
        Owner      = "acotales"
        RawBaseUrl = "https://raw.githubusercontent.com/{0}/{1}/main"
    }
    RequiredFiles = [ordered]@{
        "app.ico"   = "assets/app.ico"
        "mas.cmd"   = "src/MAS_AIO.cmd"
        "LICENSE"   = "LICENSE"
        "README.md" = "README.md"
    }
}

# ==============================================================================
#  ELEVATION CHECK (GUI FRIENDLY)
# ==============================================================================
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$admin = [Security.Principal.WindowsBuiltInRole]::Administrator

if (-not $principal.IsInRole($admin)) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $psi.Verb = "RunAs"               # triggers the UAC prompt
    $psi.WindowStyle = "Hidden"       # hides the console window
    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    }
    catch {}    # ignore error when UAC prompt is cancelled
    exit
}

# ==============================================================================
#  SINGLE INSTANCE CHECK (MUTEX)
# ==============================================================================
$MutexName = 'Global\MicrosoftActivationTool_SingleInstance'
$script:Mutex = [System.Threading.Mutex]::new($false, $MutexName)
 
$acquired = $false
try {
    # WaitOne(0) = try to acquire immediately, don't block
    $acquired = $script:Mutex.WaitOne(0)
}
catch [System.Threading.AbandonedMutexException] {
    # Previous instance crashed without releasing -- we take ownership
    $acquired = $true
}
 
if (-not $acquired) {
    [System.Windows.MessageBox]::Show(
        "Another instance of the application is already running.`n" +
        "Please close the existing instance or check your taskbar.",
        "Duplicate instance detected",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Warning
    ) | Out-Null
    $script:Mutex.Dispose()
    exit
}

# ==============================================================================
#  DIRECTORY SETUP (BASE: $env:ProgramData\<AppName>)
# ==============================================================================
$AppDir = Join-Path $env:ProgramData $App.Name
$LogDir = Join-Path $AppDir "Logs"
$LogFile = Join-Path $LogDir ("init_{0}.log" -f (Get-Date -Format 'yyyyMMdd'))
 
function Write-Log {
    param(
        [string]$Level,  
        [string]$Message
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "$timestamp [$Level] $Message"
    try {
        Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
    }
    catch {}
}

function Compare-Version {
    param(
        [string]$Current, 
        [string]$Latest
    )
    # Strips leading 'v' then compares as [Version] objects
    try {
        $current = [Version]($Current.TrimStart('v'))
        $latest = [Version]($Latest.TrimStart('v'))
        return $latest.CompareTo($current)   # >0 means latest is newer
    }
    catch {
        return 0
    }
}

# Create directory tree if missing
foreach ($subPath in @($AppDir, $LogDir)) {
    if (-not (Test-Path $subPath)) {
        try {
            New-Item -ItemType Directory -Path $subPath -Force | Out-Null
            Write-Log 'INFO' "Created directory: $subPath"
        }
        catch {
            Write-Log 'ERROR' "Failed to create directory $subPath -- $_"
            [System.Windows.MessageBox]::Show(
                "Error : Please re-install the application.",
                "Initialization failure",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            ) | Out-Null
            try { $script:Mutex.ReleaseMutex() } catch {}
            try { $script:Mutex.Dispose() } catch {}
            exit
        }
    }
}
 
Write-Log 'INFO' "App directory: $AppDir"
Write-Log 'INFO' "Starting initialization for v$($App.Version)"
 
# ==============================================================================
#  FILE INTEGRITY CHECK + AUTO-DOWNLOAD
# ==============================================================================
$WebClient = New-Object System.Net.WebClient
$missing = [System.Collections.Generic.List[string]]::new()
$failed = [System.Collections.Generic.List[string]]::new()
 
foreach ($entry in $App.RequiredFiles.GetEnumerator()) {
    # detect if the required file has a directory
    $localPath = Join-Path $AppDir $entry.Value
    $subPath = Split-Path $localPath -Parent

    if (-not (Test-Path $subPath)) {
        New-Item -ItemType Directory -Path $subPath -Force | Out-Null
    }

    if (-not (Test-Path $localPath)) {
        $missing.Add($entry.Key)
        Write-Log 'WARN' "Missing file: $($entry.Key)"
    }
}
 
if ($missing.Count -gt 0) {
    Write-Log 'INFO' "$($missing.Count) missing file(s) -- attempting download"
 
    foreach ($fileName in $missing) {
        $localPath = Join-Path $AppDir $App.RequiredFiles[$fileName]
        $remotePath = $App.RequiredFiles[$fileName]
        $rawBaseUrl = $App.Repo.RawBaseUrl -f $App.Repo.Owner, $App.Repo.Name
        $remoteUrl = "$rawBaseUrl/$remotePath"
 
        try {
            Write-Log 'INFO' "Downloading: $remoteUrl"
            $WebClient.DownloadFile($remoteUrl, $localPath)
            Write-Log 'INFO' "Downloaded OK: $fileName"
        }
        catch {
            Write-Log 'ERROR' "Download failed for $fileName -- $_"
            $failed.Add($fileName)
        }
    }
 
    if ($failed.Count -gt 0) {
        Write-Log 'ERROR' "Aborting -- $($failed.Count) file(s) failed to download"
        [System.Windows.MessageBox]::Show(
            "Error : Failed to download files.`n" + 
            "Please check your internet connection.",
            "Missing files",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
        try { $script:Mutex.ReleaseMutex() } catch {}
        try { $script:Mutex.Dispose() } catch {}
        exit
    }

    Write-Log 'INFO' 'All missing files restored -- continuing launch'
}
 
$WebClient.Dispose()

# ==============================================================================
#  VERSION CHECK + UPDATE (GitHub Releases API)
# ==============================================================================
$owner = $App.Repo.Owner
$repo = $App.Repo.Name
$apiUrl = "https://api.github.com/repos/$owner/$repo/releases/latest"

try {
    Write-Log 'INFO' "Checking for updates at: $apiUrl"
    $request = [System.Net.HttpWebRequest]::Create($apiUrl)
    $request.Method = 'GET'
    $request.Timeout = 8000
    $request.UserAgent = "MicrosoftActivationTool/$($App.Version)"
    $request.Accept = 'application/vnd.github+json'

    $response = $request.GetResponse()
    $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
    $json = $reader.ReadToEnd()
    $reader.Close()
    $response.Close()

    $tagMatch = [regex]::Match($json, '"tag_name"\s*:\s*"([^"]+)"')
    $bodyMatch = [regex]::Match($json, '"body"\s*:\s*"([^"]*)"')
    $urlMatch = [regex]::Match($json, '"html_url"\s*:\s*"([^"]+)"')
    # Grab the first .ps1 asset download URL, if the release ships one
    $assetMatch = [regex]::Match($json, '"browser_download_url"\s*:\s*"([^"]+\.ps1)"')

    if ($tagMatch.Success) {
        $latestTag = $tagMatch.Groups[1].Value
        $releaseUrl = if ($urlMatch.Success) { $urlMatch.Groups[1].Value } else { '' }
        $downloadUrl = if ($assetMatch.Success) { $assetMatch.Groups[1].Value } else { '' }
        $notes = if ($bodyMatch.Success) {
            $bodyMatch.Groups[1].Value -replace '\\n', "`n" -replace '\\r', ''
        }
        else { 'No release notes available.' }

        Write-Log 'INFO' "Current: v$($App.Version)  |  Latest: $latestTag"

        $cmp = Compare-Version -Current $App.Version -Latest $latestTag

        if ($cmp -gt 0) {
            Write-Log 'INFO' "Update available: $latestTag"

            $answer = [System.Windows.MessageBox]::Show(
                "Version $latestTag is available (you have v$($App.Version)).`n`n" +
                "Release notes:`n$notes`n`nWould you like to update now?",
                'Update Available',
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Information
            )

            # ── NEW VERSION UPDATE ────────────────────────────────────────────
            if ($answer -eq [System.Windows.MessageBoxResult]::Yes) {

                if ($downloadUrl -ne '') {
                    try {
                        $currentPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
                        $tempPath = "$currentPath.new"
                        $updaterPath = "$env:TEMP\update_$repo.bat"

                        Write-Log 'INFO' "Downloading $latestTag from: $downloadUrl"

                        $wc = New-Object System.Net.WebClient
                        $wc.Headers.Add('User-Agent', "MAT/$($App.Version)")
                        $wc.DownloadFile($downloadUrl, $tempPath)


                        # Use the self-replacing batch script that:
                        #   1. Waits for this PowerShell process to exit
                        #   2. Copies the downloaded file over the current script
                        #   3. Re-launches the updated script
                        #   4. Cleans up temp files
                        $currentScriptPath = $PSCommandPath
                        $batchContent = $batchContent -f $tempPath, $currentScriptPath
                        Set-Content -Path $updaterPath -Value $batchContent -Encoding ASCII
                        Write-Log 'INFO' "Launching updater batch: $updaterPath"
                        Start-Process cmd.exe -ArgumentList "/c `"$updaterPath`"" -WindowStyle Hidden
                        try { $script:Mutex.ReleaseMutex() } catch {}
                        try { $script:Mutex.Dispose() } catch {}
                        exit
                    }
                    catch {
                        Write-Log 'WARN' "Auto-update failed: $_  -- opening release page instead"
                        if ($releaseUrl -ne '') { Start-Process $releaseUrl }
                    }
                }
            }
        }
        elseif ($cmp -lt 0) {
            Write-Log 'INFO' 'Running pre-release or dev build -- no update needed'
        }
        else {
            Write-Log 'INFO' 'Application is up to date'
        }
    }
    else {
        Write-Log 'WARN' 'Could not parse release tag from GitHub API response'
    }
}
catch [System.Net.WebException] {
    Write-Log 'WARN' "Update check failed (network): $($_.Exception.Message)"
}
catch {
    Write-Log 'WARN' "Update check failed (unexpected): $_"
}

Write-Log 'INFO' 'Initialization complete -- launching GUI'

# =============================================================
#  BUILD THE WINDOW FROM XAML
# =============================================================
$Reader = New-Object System.Xml.XmlNodeReader $XAML
$Window = [Windows.Markup.XamlReader]::Load($Reader)

$Window.Title = $App.Name

# Convert Base64 to byte array
try {
    $bytes = [Convert]::FromBase64String($icoBase64)

    # Create icon from memory stream
    $stream = [System.IO.MemoryStream]::new($bytes)
    $iconDrawing = [System.Drawing.Icon]::new($stream)
    $stream.Close()
    
    # Convert Drawing.Icon to BitmapSource
    $icon = [System.Windows.Interop.Imaging]::CreateBitmapSourceFromHIcon(
        $iconDrawing.Handle,
        [System.Windows.Int32Rect]::Empty,
        [System.Windows.Media.Imaging.BitmapSizeOptions]::FromEmptyOptions()
    )
}
catch {
    $iconPath = Join-Path $AppDir $App.RequiredFiles["app.ico"]
    $icon = (Resolve-Path $iconPath).Path
}

$Window.Icon = $icon

# ── Microsoft Activation Script ───────────────────────────────────────────────
$MASScript = Join-Path $AppDir $App.RequiredFiles["mas.cmd"]

# ── Bind named elements to variables ──────────────────────────────────────────
$ActivateWindowsButton = $Window.FindName('Button1')
$ActivateOfficeButton = $Window.FindName('Button2')
$ProgressBar = $Window.FindName('ProgressBar')
$StatusLabel = $Window.FindName('StatusLabel')
$VersionLabel = $Window.FindName('Subtitle')

$VersionLabel.Text = "Version $($App.Version)"
# =============================================================
#  Async Runspace helper
#  The background Runspace sleeps 10 s then posts a result back
#  to the UI thread via the Dispatcher — the GUI never freezes.
# =============================================================
$ActivateWindowsButton.Add_Click({
        # ── Disable button & show progress ──────────────────────
        $ActivateWindowsButton.IsEnabled = $false
        $ActivateOfficeButton.IsEnabled = $false    # code to prevent conflicts while in execution
        $ActivateWindowsButton.Content = "Processing"
        $ProgressBar.Visibility = [System.Windows.Visibility]::Visible
        $StatusLabel.Text = "Initializing..."
        $StatusLabel.Foreground = [System.Windows.Media.Brushes]::LightYellow

        # ── Capture a dispatcher reference for the UI thread ────
        $dispatcher = $Window.Dispatcher

        # ── Spin up a background Runspace ───────────────────────
        $Runspace = [RunspaceFactory]::CreateRunspace()
        $Runspace.ApartmentState = [System.Threading.ApartmentState]::STA
        $Runspace.ThreadOptions = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
        $Runspace.Open()

        $PS = [PowerShell]::Create()
        $PS.Runspace = $Runspace

        # Pass UI references into the Runspace via $using: (PS5+)
        # Note: we pass $dispatcher so the background thread can
        #       safely update the UI via Invoke().
        [void]$PS.AddScript({

                param(
                    $dispatcher, 
                    $appButton1, 
                    $appButton2, 
                    $progressBar, 
                    $statusLabel,
                    $scriptPath,
                    $logFile,
                    $appWindow
                )

                # ── Redefine Write-Log inside this runspace ───────────────────
                function Write-Log {
                    param([string]$Level, [string]$Message)
                    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                    $line = "$timestamp [$Level] $Message"
                    try {
                        Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
                    }
                    catch {}
                }

            
                $mas = $scriptPath
                
                Write-Log 'INFO' 'Activate Windows button clicked -- background task started'
                
                $dispatcher.Invoke([System.Action] {
                        $statusLabel.Text = "Checking application files..."
                        $statusLabel.Foreground = [System.Windows.Media.Brushes]::LightYellow
                    }.GetNewClosure())

                if (-not (Test-Path $mas -PathType Leaf)) {
                    $url = @(
                        "https:", "", "raw.githubusercontent.com", "massgravel",
                        "Microsoft-Activation-Scripts", "refs", "heads",
                        "master", "MAS", "All-In-One-Version-KL", "MAS_AIO.cmd"
                    )

                    $subPath = Split-Path $mas -Parent
                    if (-not (Test-Path $subPath)) {
                        New-Item -ItemType Directory -Path $subPath -Force | Out-Null
                    }

                    try {
                        Write-Log 'INFO' "Downloading activation script from GitHub"

                        $dispatcher.Invoke([System.Action] {
                                $statusLabel.Text = "Downloading activation script"
                                $statusLabel.Foreground = [System.Windows.Media.Brushes]::LightYellow
                            }.GetNewClosure())

                        Invoke-WebRequest $($url -join '/') -OutFile $mas
                        Write-Log 'INFO' "Download complete: $mas"
                    }
                    catch {
                        Write-Log 'ERROR' "Failed to download activation script -- $_"
                        $outcome = "Failure"
                    }
                }

                if ($outcome -ne "Failure") {

                    # ── Detect OS role ───────────────────────────────────────────
                    Write-Log 'INFO' "Detecting OS type..."

                    try {
                        $osInfo = Get-WmiObject -Class Win32_OperatingSystem
                        $productType = $osInfo.ProductType

                        $osRole = switch ($productType) {
                            1 { 'Workstation' }
                            2 { 'DomainController' }
                            3 { 'Server' }
                            default { 'Unknown' }
                        }

                        Write-Log 'INFO' "OS role detected: $osRole (ProductType=$productType)"
                    }
                    catch {
                        $osRole = 'Unknown'
                        Write-Log 'WARN' "Could not determine OS type -- defaulting to ESU args: $_"
                    }

                    # ── Select argument list based on OS role ────────────────────
                    $masArgs = if ($osRole -eq 'Workstation') {
                        "/c `"$mas`" /HWID /S"
                    }
                    else {
                        "/c `"$mas`" /Z-WindowsESUOffice /S"
                    }

                    Write-Log 'INFO' "Using activation args: $masArgs"

                    $dispatcher.Invoke([System.Action] {
                            $statusLabel.Text = "Activating Windows ($osRole) - Please wait..."
                            $statusLabel.Foreground = [System.Windows.Media.Brushes]::LightGreen
                        }.GetNewClosure())

                    try {
                        Write-Log 'INFO' "Launching MAS script: $mas"

                        $runArgs = @{
                            ArgumentList = $masArgs
                            Wait         = $true
                            PassThru     = $true
                            WindowStyle  = "Hidden"
                        }

                        $proc = Start-Process cmd.exe @runArgs

                        if ($proc.ExitCode -eq 0) {
                            $outcome = "Success"
                            Write-Log 'INFO' "Activation succeeded (ExitCode=0)"
                        }
                        else {
                            throw "Windows activation failed with ExitCode=$($proc.ExitCode)"
                        }
                    }
                    catch {
                        Write-Log 'ERROR' "Activation error -- $_"
                        $outcome = "Failure"
                    }
                }

                # ── Marshal result back to UI thread ────────────────
                $dispatcher.Invoke([System.Action] {
                        # Hide progress, re-enable button
                        $progressBar.Visibility = [System.Windows.Visibility]::Collapsed
                        $appButton1.IsEnabled = $true
                        $appButton2.IsEnabled = $true # re-enable both buttons
                        $appButton1.Content = "Activate Windows"

                        if ($outcome -eq "Success") {
                            $statusLabel.Text = "Microsoft Windows - Activation Successful"
                            $statusLabel.Foreground = [System.Windows.Media.Brushes]::LightGreen

                            [System.Windows.MessageBox]::Show(
                                "Microsoft Windows Activated - Permanently",
                                "Success",
                                [System.Windows.MessageBoxButton]::OK,
                                [System.Windows.MessageBoxImage]::Information
                            ) | Out-Null
                        }
                        else {
                            $masExists = Test-Path $mas -PathType Leaf
                            if (-not $masExists) {
                                $statusLabel.Text = "Failed to download activator"
                            }
                            else {
                                $statusLabel.Text = "Activation failed"
                            }
                            $statusLabel.Foreground = [System.Windows.Media.Brushes]::Salmon
                            [System.Windows.MessageBox]::Show(
                                "The process encountered an error and could not complete.`n`nPlease review the logs and try again.",
                                "Failure",
                                [System.Windows.MessageBoxButton]::OK,
                                [System.Windows.MessageBoxImage]::Error
                            ) | Out-Null
                        }

                        $appWindow.Topmost = $true
                        $appWindow.Activate()
                        $appWindow.Focus()
                        $appWindow.Topmost = $false

                    }, [System.Windows.Threading.DispatcherPriority]::Normal)

            }.GetNewClosure())

        [void]$PS.AddParameters(@{
                dispatcher  = $dispatcher
                appButton1  = $ActivateWindowsButton
                appButton2  = $ActivateOfficeButton
                progressBar = $ProgressBar
                statusLabel = $StatusLabel
                scriptPath  = $MASScript
                logFile     = $LogFile
                appWindow   = $Window
            })

        # Fire-and-forget (async)
        [void]$PS.BeginInvoke()
    })

# =============================================================
#  Second Button (5-second task)
# =============================================================
$ActivateOfficeButton.Add_Click({

        # ── Disable button & show progress ──────────────────────
        $ActivateOfficeButton.IsEnabled = $false
        $ActivateWindowsButton.IsEnabled = $false # prevent conflicts
        $ActivateOfficeButton.Content = "Processing"
        $ProgressBar.Visibility = [System.Windows.Visibility]::Visible
        $StatusLabel.Text = "Processing Task - please wait..."
        $StatusLabel.Foreground = [System.Windows.Media.Brushes]::LightBlue

        # ── Capture dispatcher ───────────────────────────────────
        $dispatcher = $Window.Dispatcher

        # ── Create Runspace ──────────────────────────────────────
        $Runspace = [RunspaceFactory]::CreateRunspace()
        $Runspace.ApartmentState = [System.Threading.ApartmentState]::STA
        $Runspace.ThreadOptions = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
        $Runspace.Open()

        $PS = [PowerShell]::Create()
        $PS.Runspace = $Runspace

        [void]$PS.AddScript({
                param($dispatcher, $appButton2, $appButton1, $progressBar, $statusLabel)

                # ── Simulate 5-second workload ─────────────────────
                Start-Sleep -Seconds 2

                # ── Random outcome ────────────────────────────────
                $outcome = if ((Get-Random -Minimum 1 -Maximum 11) -le 8) { 'Success' } else { 'Failure' }

                # ── Return to UI thread ───────────────────────────
                $dispatcher.Invoke([System.Action] {

                        $progressBar.Visibility = [System.Windows.Visibility]::Collapsed
                        $appButton2.IsEnabled = $true
                        $appButton1.IsEnabled = $true
                        $appButton2.Content = "Activate MS Office"

                        if ($outcome -eq 'Success') {
                            $statusLabel.Text = "Microsoft Office - Activation Successful"
                            $statusLabel.Foreground = [System.Windows.Media.Brushes]::LightGreen

                            [System.Windows.MessageBox]::Show(
                                "Microsoft Office - Activation Complete",
                                "Success",
                                [System.Windows.MessageBoxButton]::OK,
                                [System.Windows.MessageBoxImage]::Information
                            ) | Out-Null
                        }
                        else {
                            $statusLabel.Text = "Task 2: Failed"
                            $statusLabel.Foreground = [System.Windows.Media.Brushes]::Salmon

                            [System.Windows.MessageBox]::Show(
                                "Task 2 failed during execution.",
                                "Failure",
                                [System.Windows.MessageBoxButton]::OK,
                                [System.Windows.MessageBoxImage]::Error
                            ) | Out-Null
                        }

                    }, [System.Windows.Threading.DispatcherPriority]::Normal)

            }.GetNewClosure())

        [void]$PS.AddParameters(@{
                dispatcher  = $dispatcher
                appButton2  = $ActivateOfficeButton
                progressBar = $ProgressBar
                statusLabel = $StatusLabel
                appButton1  = $ActivateWindowsButton
            })

        # ── Run async ────────────────────────────────────────────
        [void]$PS.BeginInvoke()
    })

# =============================================================
#  Show the Window (blocking call — returns when closed)
#  Mutex is released in finally, guaranteed
# =============================================================
# try {
#     [void]$Window.ShowDialog()
#     $Window.Topmost = $true
#     $Window.Activate()
#     $Window.Focus()
#     $Window.Topmost = $false
# }
# finally {
#     try { $script:Mutex.ReleaseMutex() } catch { }
#     try { $script:Mutex.Dispose() } catch { }
# }

[void]$Window.ShowDialog()
$Window.Topmost = $true
$Window.Activate()
$Window.Focus()
$Window.Topmost = $false

try { $script:Mutex.ReleaseMutex() } catch { }
try { $script:Mutex.Dispose() } catch { }

