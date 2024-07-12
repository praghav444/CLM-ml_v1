module controlMod

  !-----------------------------------------------------------------------
  ! !DESCRIPTION:
  ! Initialize namelist run control variables
  !
  ! !USES:
  use abortutils,   only : endrun
  use shr_kind_mod, only : r8 => shr_kind_r8
  !
  ! !PUBLIC TYPES:
  implicit none
  !
  ! !PUBLIC MEMBER FUNCTIONS:
  public :: control
  !-----------------------------------------------------------------------

contains

  !-----------------------------------------------------------------------
  subroutine control (ntim, clm_start_ymd, clm_start_tod, diratm, dirclm, dirout, dirin, par1, par2, par3, par4)
    !
    ! !DESCRIPTION:
    ! Initialize run control variables from namelist
    !
    ! !USES:
    use clm_time_manager, only : start_date_ymd, start_date_tod, dtstep
    use clm_varctl, only : iulog
    use MLclm_varctl, only : clm_phys
    use TowerDataMod, only : ntower, tower_id, tower_num, tower_time
    !
    ! !ARGUMENTS:
    implicit none
    integer, intent(out) :: ntim                ! Number of time steps to process
    integer, intent(out) :: clm_start_ymd       ! CLM history file start date (yyyymmdd format)
    integer, intent(out) :: clm_start_tod       ! CLM history file start time-of-day (seconds past 0Z UTC)
    character(len=256), intent(out) :: diratm   ! Tower meteorology file directory path
    character(len=256), intent(out) :: dirclm   ! CLM history file directory path
    character(len=256), intent(out) :: dirout   ! Model output file directory path
    character(len=256), intent(out) :: dirin    ! Model input file directory path for profile data

    real(r8), intent(out) :: par1              ! Parameter (pbeta_lai)
    real(r8), intent(out) :: par2              ! Parameter (qbeta_lai)
    real(r8), intent(out) :: par3              ! Parameter (psi50_gs)
    real(r8), intent(out) :: par4              ! Parameter (vcmaxpft)


    !
    ! !LOCAL VARIABLES:
    character(len=6) :: tower_name              ! Flux tower site to process
    character(len=6) :: stop_option             ! Character flag to specify run length
    integer :: start_ymd                        ! Run start date in yyyymmdd format
    integer :: start_tod                        ! Time-of-day (UTC) of the start date (seconds past 0Z; 0 to 86400)
    integer :: stop_n                           ! Length of simulation

    integer :: i                                ! Index
    integer :: steps_per_day                    ! Number of time steps per day

    real(r8) :: p1              ! Parameter (pbeta_lai)
    real(r8) :: p2              ! Parameter (qbeta_lai)
    real(r8) :: p3              ! Parameter (psi50_gs)
    real(r8) :: p4              ! Parameter (vcmaxpft)
    character(len=256) :: out_dir   ! Model output file directory path
    namelist /clmML_inparm/ tower_name, start_ymd, start_tod, stop_option, &
    stop_n, clm_start_ymd, clm_start_tod, p1, p2, p3, p4, out_dir
    !---------------------------------------------------------------------

    ! Default namelist variables

    tower_name = ' '      ! Flux tower site to process
    start_ymd = 0         ! Run start date in yyyymmdd format
    start_tod = 0         ! Time-of-day (UTC) of the start date (seconds past 0Z; 0 to 86400)
    stop_option = ' '     ! Sets the run length as days ('ndays') or timesteps ('nsteps')
    stop_n = 0            ! Sets the length of the run (days or timesteps depending on stop_option)
    clm_start_ymd = 0     ! CLM history file start date (yyyymmdd format)
    clm_start_tod = 0     ! CLM history file start time-of-day (seconds past 0Z UTC)
    p1 = 11.5_r8           ! Parameter (pbeta_lai)
    p2 = 3.5_r8            ! Parameter (qbeta_lai)
    p3 = -2.3_r8            ! Parameter (psi50_gs)
    p4 = 70.1_r8            ! Parameter (vcmaxpft)
    ! Read namelist file

    write(iulog,*) 'Attempting to read namelist file .....'
    read (5, clmML_inparm)
    write(iulog,*) 'Successfully read namelist file'

    ! Set parameters
    par1 = p1
    par2 = p2
    par3 = p3
    par4 = p4
    ! Set calendar variables

    start_date_ymd = start_ymd
    start_date_tod = start_tod

    ! CHATS and UMBSmw use CLM5.0 soils

    if (tower_name == 'CHATS7') clm_phys = 'CLM5_0'
    if (tower_name == 'UMBSmw') clm_phys = 'CLM5_0'

    ! Specify input and output directories

    diratm = ' '
    dirclm = ' '
    dirout = ' '

    diratm = '../input_files/tower-forcing/'
    if (clm_phys == 'CLM4_5') then
       dirclm = '../input_files/clm4_5/'
    else if (clm_phys == 'CLM5_0') then
       dirclm = '../input_files/clm5_0/'
    end if
    !dirout = '../output_files/'
    dirout = out_dir 
    dirin = '../output_files/'

    ! Match tower site to correct index for TowerDataMod arrays

    tower_num = 0
    do i = 1, ntower
       if (tower_name == tower_id(i)) then
          tower_num = i
          exit
       else
          cycle
       end if
    end do

    if (tower_num == 0) then
       write (iulog,*) 'control error: tower site = ',tower_name, ' not found'
       call endrun()
    end if

    ! Time step of forcing data (in seconds). This varies among tower sites.

    dtstep = tower_time(tower_num) * 60

    ! Set length of simulation

    if (stop_option == 'nsteps') then
       ntim = stop_n                       ! Number of time steps to execute
    else if (stop_option == 'ndays') then
       steps_per_day = 86400 / dtstep      ! Number of time steps per day
       ntim = steps_per_day * stop_n       ! Number of time steps to execute
    end if
  end subroutine control

end module controlMod
