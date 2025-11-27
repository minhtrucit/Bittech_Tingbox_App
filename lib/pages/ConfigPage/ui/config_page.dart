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
  final TextEditingController _unitNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _sepayApiKeyController = TextEditingController();
  List<Bank> _bankList = [];
  bool _isApiKeyVisible = false;
  int? _selectedBankIndex;
  int _printModeGroupValue = 1; // 0: Tự động in, 1: Không in, 2: Mặc định
  late bool _isEditing;
  bool _useConfigBankList = true;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.config == null;
    _populateFields();
    if (widget.config == null) {
      _useConfigBankList = false;
      _getBankList();
    }
  }

  void _populateFields() {
    if (widget.config != null) {
      if (widget.config!.bankAccounts.isNotEmpty) {
        final bankAccount = widget.config!.bankAccounts.first;
        _accountNumberController.text = bankAccount.accountNumber;
        _accountNameController.text = bankAccount.accountName;
        // Note: Bank selection logic is limited as we don't have the full bank list here.
        // We might need to fetch banks or just show the current one.
      }

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

  void _getBankList() {
    context.read<ConfigBloc>().add(GetBankEvent());
  }

  @override
  void dispose() {
    _unitNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _sepayApiKeyController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (widget.config == null) return;

    final updatedConfig = ConfigModel(
      id: widget.config!.id,
      unitName: _unitNameController.text,
      sepayApiKey: _sepayApiKeyController.text,
      printMode: _getPrintModeFromValue(_printModeGroupValue),
      createdAt: widget.config!.createdAt,
      updatedAt: DateTime.now(),
      configUsers: widget.config!.configUsers,
      bankAccounts: _updateBankAccounts(widget.config!.bankAccounts),
    );

    context.read<ConfigBloc>().add(SaveConfigEvent(config: updatedConfig));
    setState(() {
      _isEditing = false;
    });
  }

  List<ConfigBankAccount> _updateBankAccounts(
    List<ConfigBankAccount> currentAccounts,
  ) {
    if (currentAccounts.isEmpty) {
      return [];
    }
    final first = currentAccounts.first;
    final updatedFirst = ConfigBankAccount(
      id: first.id,
      configId: first.configId,
      bankId: first.bankId,
      accountNumber: _accountNumberController.text,
      accountName: _accountNameController.text,
      isDefault: first.isDefault,
      isActive: first.isActive,
      createdAt: first.createdAt,
      updatedAt: DateTime.now(),
      bank: first.bank,
    );

    return [updatedFirst, ...currentAccounts.skip(1)];
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
      listenWhen: (previous, current) => current is BankLoaded,
      listener: (context, state) {
        if (state is BankLoaded) {
          _bankList = Bank.getTransferSupportedBanks(state.banks);
          setState(() {});
        }
      },
      child: AppScaffold(
        backgroundColor: Colors.white,
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
                  _getBankList();
                  setState(() {
                    _isEditing = true;
                    _useConfigBankList = false;
                  });
                },
              ),
          ],
        ),
        body: SafeArea(
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
                      ),
                      SizedBox(height: 24.h),

                      _buildLabel('Ngân hàng'),
                      SizedBox(height: 8.h),
                      _buildBankGrid(),
                      SizedBox(height: 24.h),

                      _buildLabel('Số tài khoản'),
                      SizedBox(height: 8.h),
                      _buildTextField(
                        controller: _accountNumberController,
                        hintText: 'Nhập số tài khoản',
                        keyboardType: TextInputType.number,
                        enabled: _isEditing,
                      ),
                      SizedBox(height: 24.h),

                      _buildLabel('Tên tài khoản'),
                      SizedBox(height: 8.h),
                      _buildTextField(
                        controller: _accountNameController,
                        hintText: 'Nhập tên tài khoản',
                        enabled: _isEditing,
                      ),
                      SizedBox(height: 24.h),

                      _buildLabel('Sepay API Key'),
                      SizedBox(height: 8.h),
                      _buildTextField(
                        controller: _sepayApiKeyController,
                        hintText: '....................',
                        obscureText: !_isApiKeyVisible,
                        enabled: _isEditing,
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
                    ],
                  ),
                ),
              ),
              if (_isEditing) _buildSaveButton(),
            ],
          ),
        ),
      ),
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
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
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

  Widget _buildBankGrid() {
    final isUsingConfig = widget.config != null && _useConfigBankList;

    final banks =
        isUsingConfig
            ? widget.config!.bankAccounts.map((e) => e.bank!).toList()
            : _bankList;

    return AbsorbPointer(
      absorbing: !_isEditing,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 1.0,
        ),
        itemCount: banks.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedBankIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedBankIndex = index;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.blue.withValues(alpha: 0.1)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                image: DecorationImage(
                  image: NetworkImage(banks[index].logo),
                  fit: BoxFit.contain,
                ),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
            ),
          );
        },
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
