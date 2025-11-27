import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_state.dart';
import 'package:ting_box/ting_box.dart';
import 'package:ting_box/models/config_model.dart';
import 'package:ting_box/models/bank.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_bloc.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_event.dart';
import 'package:flutter/services.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key, this.config});
  final ConfigModel? config;

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _unitNameController = TextEditingController();
  final TextEditingController _sepayUrlController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  List<Bank> _bankList = [];
  int _printModeGroupValue = 1;
  bool _isEditing = false;
  bool isAdmin = false;
  File? _logoFile;
  String? existingLogo;

  @override
  void initState() {
    super.initState();
    _populateFields();
    _getUserInfo();
    _getBankList();
    if (widget.config != null && widget.config!.logo?.isNotEmpty == true) {
      existingLogo = widget.config!.logo;
    }
  }

  void _getBankList() {
    context.read<ConfigBloc>().add(GetBankEvent());
    context.read<ConfigBloc>().add(LoadSepayInfoFromLocalEvent());
  }

  Future<void> _getUserInfo() async {
    final user = await UserRepository.getUser();
    setState(() {
      isAdmin = user?.roleId == 1 || user?.roleId == 2;
    });
  }

  void _populateFields() {
    if (widget.config != null) {
      _unitNameController.text = widget.config!.unitName ?? '';
      _phoneController.text = widget.config!.phone ?? '';
      _addressController.text = widget.config!.address ?? '';
      switch (widget.config!.printMode) {
        case PrintMode.auto:
          _printModeGroupValue = 0;
          break;
        case PrintMode.none:
          _printModeGroupValue = 1;
          break;
        case PrintMode.manual:
          _printModeGroupValue = 2;
          break;
      }
    }
  }

  Future<void> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _logoFile = File(image.path);
      });
    }
  }

  Future<void> pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _logoFile = File(image.path);
      });
    }
  }

  @override
  void dispose() {
    _unitNameController.dispose();
    _sepayUrlController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Update existing config
    final updatedConfig = ConfigModel(
      id: widget.config!.id,
      unitName: _unitNameController.text.trim(),
      sepayApiKey: widget.config!.sepayApiKey,
      printMode: _getPrintModeFromValue(_printModeGroupValue),
      createdAt: widget.config!.createdAt,
      updatedAt: DateTime.now(),
      configUsers: widget.config!.configUsers,
      bankAccounts: widget.config!.bankAccounts,
      logo: _logoFile != null ? _logoFile!.path : widget.config!.logo,
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );

    context.read<ConfigBloc>().add(UpdateConfigEvent(config: updatedConfig));
  }

  PrintMode _getPrintModeFromValue(int value) {
    switch (value) {
      case 0:
        return PrintMode.auto;
      case 1:
        return PrintMode.none;
      case 2:
        return PrintMode.manual;
      default:
        return PrintMode.none;
    }
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLabel("Hình ảnh Logo"),
            Text(
              _logoFile != null || existingLogo != null ? "1/1" : "0/1",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          "Chọn 1 ảnh",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              builder: (context) => _buildImagePickerSheet(),
            );
          },

          child: IgnorePointer(
            ignoring: !_isEditing,
            child: Container(
              height: 130,
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              decoration: _boxDecoration(),
              child: Center(child: _buildPhotoContent(isEdit: _isEditing)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoContent({bool isEdit = false}) {
    // Ưu tiên ảnh người dùng chọn
    if (_logoFile != null) {
      return _buildImageWithRemove(
        Image.file(
          File(_logoFile!.path),
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
        () {
          setState(() => _logoFile = null);
        },
      );
    }

    // Nếu không có ảnh mới nhưng có logo từ API
    if (existingLogo != null) {
      return _buildImageWithRemove(
        Image.network(
          existingLogo!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
        () {
          setState(() => existingLogo = null);
        },
      );
    }

    // Nếu không có ảnh → hiển thị nút thêm
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 40,
          color: isEdit ? Colors.blue : Colors.grey,
        ),
        SizedBox(height: 8),
        Text(
          "Thêm hình ảnh",
          style: TextStyle(color: isEdit ? Colors.blue : Colors.grey),
        ),
        SizedBox(height: 4),
        Text(
          "Chọn Logo cho doanh nghiệp của bạn",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildImageWithRemove(Widget imageWidget, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: imageWidget),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerSheet() {
    return SizedBox(
      height: 120,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Chọn từ thư viện"),
            onTap: () {
              Navigator.pop(context);
              pickImageFromGallery();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Chụp ảnh"),
            onTap: () {
              Navigator.pop(context);
              pickImageFromCamera();
            },
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
    );
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Đã sao chép vào bộ nhớ tạm'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfigBloc, ConfigState>(
      listener: (context, state) {
        if (state is BankLoaded) {
          _bankList = Bank.getTransferSupportedBanks(state.banks);
          // No setState needed as dialog uses stateful builder or reads from _bankList
        } else if (state is ConfigCreateSuccess ||
            state is ConfigUpdateSuccess) {
          DialogUtils.showAppDialog(
            onFirstAction: () => Navigator.pop(context),
            firstActionText: 'Đóng',
            context: context,
            title: 'Thành công',
            content: 'Lưu cấu hình thành công',
          );
        } else if (state is SepayInfoLoaded) {
          _sepayUrlController.text = state.url;
        }
      },
      child: AppScaffold(
        backgroundColor: AppColors.white,
        appBar: AppAppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: TitleAppbarText(title: 'Cấu hình'),
          centerTitle: true,
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
              ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Tên đơn vị'),
                        SizedBox(height: 8.h),
                        _buildTextField(
                          controller: _unitNameController,
                          hintText: 'Nhập tên đơn vị',
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tên đơn vị';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),
                        _buildLabel('Số điện thoại'),
                        SizedBox(height: 8.h),
                        _buildTextField(
                          controller: _phoneController,
                          hintText: 'Nhập số điện thoại',
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập số điện thoại';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),
                        _buildLabel('Địa chỉ'),
                        SizedBox(height: 8.h),
                        _buildTextField(
                          controller: _addressController,
                          hintText: 'Nhập địa chỉ',
                          enabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập địa chỉ';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24.h),
                        _buildPhotoSection(),
                        SizedBox(height: 24.h),
                        _buildLabel('Cấu hình Sepay'),
                        SizedBox(height: 8.h),
                        IgnorePointer(
                          ignoring: !_isEditing,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.read<ConfigBloc>().add(
                                  GetSepayInfoEvent(),
                                );
                              },
                              icon: const Icon(
                                Icons.download,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Lấy thông tin Sepay',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isEditing
                                        ? AppColors.primaryBlue
                                        : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _buildLabel('URL'),
                        SizedBox(height: 8.h),
                        _buildTextField(
                          controller: _sepayUrlController,
                          hintText: 'URL',
                          readOnly: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.copy, color: Colors.grey),
                            onPressed:
                                () =>
                                    _copyToClipboard(_sepayUrlController.text),
                          ),
                        ),
                        SizedBox(height: 24.h),

                        _buildLabel('Chế độ in'),
                        SizedBox(height: 8.h),
                        _buildPrintModeSegmentedControl(),
                        SizedBox(height: 32.h),
                        _buildLabel('Danh sách ngân hàng'),

                        // Existing Banks Section
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //   children: [
                        //     _buildLabel('Danh sách ngân hàng'),
                        //     if (_isEditing)
                        //       IgnorePointer(
                        //         child: Flexible(
                        //           child: IconButton(
                        //             onPressed: _showAddBankDialog,
                        //             icon: const Icon(Icons.add, size: 24),
                        //           ),
                        //         ),
                        //       ),
                        //   ],
                        // ),
                        SizedBox(height: 8.h),
                        _buildExistingBankList(),
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),
                if (_isEditing) _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExistingBankList() {
    if (widget.config == null || widget.config!.bankAccounts.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            'Chưa có ngân hàng nào được cấu hình',
            style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.0,
      ),
      itemCount: widget.config!.bankAccounts.length,
      itemBuilder: (context, index) {
        final bankAccount = widget.config!.bankAccounts[index];
        return Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              bankAccount.bank != null
                  ? Image.network(bankAccount.bank!.logo, fit: BoxFit.contain)
                  : const Icon(Icons.account_balance, color: Colors.grey),
        );
      },
    );
  }

  void _showAddBankDialog() {
    if (_bankList.isEmpty) {
      _getBankList();
    }

    showDialog(
      context: context,
      builder: (context) {
        int? selectedBankIndex;
        final accountNumberController = TextEditingController();
        final accountNameController = TextEditingController();
        final formKey = GlobalKey<FormState>();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
              title: const Text('Thêm ngân hàng'),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chọn ngân hàng',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        SizedBox(
                          height: 200.h,
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8.w,
                                  mainAxisSpacing: 8.h,
                                  childAspectRatio: 1.0,
                                ),
                            itemCount: _bankList.length,
                            itemBuilder: (context, index) {
                              final isSelected = selectedBankIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedBankIndex = index;
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Colors.blue.withAlpha(10)
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Colors.blue
                                              : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  padding: EdgeInsets.all(4.w),
                                  child: Image.network(
                                    _bankList[index].logo,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (selectedBankIndex == null)
                          Padding(
                            padding: EdgeInsets.only(top: 8.h),
                            child: Text(
                              'Vui lòng chọn ngân hàng',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        SizedBox(height: 16.h),
                        _buildTextField(
                          controller: accountNumberController,
                          hintText: 'Số tài khoản',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập số tài khoản';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.number,
                        ),

                        SizedBox(height: 16.h),
                        _buildTextField(
                          controller: accountNameController,
                          hintText: 'Tên tài khoản',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tên tài khoản';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                AppTextButton(
                  onPressed: () => Navigator.pop(context),
                  label: Text(
                    'Hủy',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                AppTextButton(
                  onPressed: () {
                    if (formKey.currentState!.validate() &&
                        selectedBankIndex != null) {
                      final selectedBank = _bankList[selectedBankIndex!];
                      context.read<ConfigBloc>().add(
                        CreateOrUpdateBankAccountEvent(
                          configId: widget.config!.id!,
                          bankId: selectedBank.id,
                          accountNumber: accountNumberController.text.trim(),
                          accountName: accountNameController.text.trim(),
                        ),
                      );
                      Navigator.pop(context); // Close dialog immediately
                    }
                  },
                  label: Text(
                    'Lưu',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    bool enabled = true,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      readOnly: readOnly,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        filled: !enabled,
        fillColor: !enabled ? Colors.grey[100] : null,
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildPrintModeSegmentedControl() {
    return AbsorbPointer(
      absorbing: !_isEditing,
      child: SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<int>(
          groupValue: _printModeGroupValue,
          children: {
            0: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text(
                'Tự động in',
                style: TextStyle(
                  fontSize: 14.sp,
                  color:
                      _printModeGroupValue == 0 ? Colors.white : Colors.black54,
                ),
              ),
            ),
            1: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text(
                'Không in',
                style: TextStyle(
                  fontSize: 14.sp,
                  color:
                      _printModeGroupValue == 1 ? Colors.white : Colors.black54,
                ),
              ),
            ),
            2: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Text(
                'Mặc định',
                style: TextStyle(
                  fontSize: 14.sp,
                  color:
                      _printModeGroupValue == 2 ? Colors.white : Colors.black54,
                ),
              ),
            ),
          },
          onValueChanged: (int? value) {
            if (value != null) {
              setState(() {
                _printModeGroupValue = value;
              });
            }
          },
          thumbColor: _isEditing ? Colors.blue : Colors.grey,
          backgroundColor: Colors.grey[100]!,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50.h,
        child: ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
          ),
          child: Text(
            'Lưu',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
