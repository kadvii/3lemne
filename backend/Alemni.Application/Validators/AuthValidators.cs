using Alemni.Application.DTOs;
using FluentValidation;

namespace Alemni.Application.Validators;

public class RegisterRequestValidator : AbstractValidator<RegisterRequest>
{
    public RegisterRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("البريد الإلكتروني مطلوب.")
            .EmailAddress().WithMessage("صيغة البريد الإلكتروني غير صحيحة.")
            .MaximumLength(256).WithMessage("البريد الإلكتروني يجب ألا يتجاوز 256 حرفًا.");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("كلمة المرور مطلوبة.")
            .MinimumLength(6).WithMessage("كلمة المرور يجب أن تكون 6 أحرف على الأقل.");

        RuleFor(x => x.DisplayName)
            .NotEmpty().WithMessage("الاسم المعروض مطلوب.")
            .MaximumLength(100).WithMessage("الاسم المعروض يجب ألا يتجاوز 100 حرف.");
    }
}

public class LoginRequestValidator : AbstractValidator<LoginRequest>
{
    public LoginRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("البريد الإلكتروني مطلوب.")
            .EmailAddress().WithMessage("صيغة البريد الإلكتروني غير صحيحة.");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("كلمة المرور مطلوبة.");
    }
}

public class RefreshTokenRequestValidator : AbstractValidator<RefreshTokenRequest>
{
    public RefreshTokenRequestValidator()
    {
        RuleFor(x => x.RefreshToken)
            .NotEmpty().WithMessage("رمز التحديث مطلوب.");
    }
}

