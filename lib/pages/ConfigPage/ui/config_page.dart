import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_state.dart';
import 'package:ting_box/ting_box.dart';
import 'package:ting_box/models/config_model.dart';
import 'package:ting_box/models/bank.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_bloc.dart';
import 'package:ting_box/pages/ConfigPage/bloc/config_event.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key, this.config});
  final ConfigModel? config;

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _unitNameController = TextEditingController();
  final TextEditingController _sepayApiKeyController = TextEditingController();

  List<Bank> _bankList = [];
  bool _isApiKeyVisible = false;
  int _printModeGroupValue = 1;
  bool _isEditing = false;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _populateFields();
    _getUserInfo();
    _getBankList();
  }

  void _getBankList() {
    context.read<ConfigBloc>().add(GetBankEvent());
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
      _sepayApiKeyController.text = widget.config!.sepayApiKey ?? '';
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

  @override
  void dispose() {
    _unitNameController.dispose();
    _sepayApiKeyController.dispose();
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
      sepayApiKey: _sepayApiKeyController.text.trim(),
      printMode: _getPrintModeFromValue(_printModeGroupValue),
      createdAt: widget.config!.createdAt,
      updatedAt: DateTime.now(),
      configUsers: widget.config!.configUsers,
      bankAccounts: widget.config!.bankAccounts,
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

                        _buildLabel('Sepay API Key'),
                        SizedBox(height: 8.h),
                        _buildTextField(
                          controller: _sepayApiKeyController,
                          hintText: '....................',
                          obscureText: !_isApiKeyVisible,
                          enabled: _isEditing && isAdmin,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isApiKeyVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isApiKeyVisible = !_isApiKeyVisible;
                              });
                            },
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
          child: bankAccount.bank != null
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
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
